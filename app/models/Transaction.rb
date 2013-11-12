class Transaction < ActiveRecord::Base

  CURRENCIES = {
    1 => "Mastercoin",
    2 => "Test Mastercoin",
  }

  acts_as_list column: :app_position

  scope :real, -> { where(currency_id: 1) }
  scope :test, -> { where(currency_id: 2) }
  scope :valid, -> { where(invalid_tx: false) }

  default_scope { order('app_position DESC') } 

  after_create :set_app_position!

  def set_app_position!
    # find the correct position
    transaction = Transaction.where("block_height = ? AND position < ?", self.block_height, self.position).order("app_position DESC").first
    unless transaction
      transaction = Transaction.where("block_height < ?", self.block_height).order("app_position DESC").first
    end

    if transaction
      self.insert_at(transaction.app_position + 1)
    else # I'm the king so I should be number one
      self.insert_at(1)
    end
  end

  def as_json(options = {})
    options.reverse_merge!({except: [:id, :is_exodus]})
    super
  end

  def kind
    return "Simple Send" if self.type == "SimpleSend"
    return "Exodus" if self.type == "ExodusTransaction"
    return "Selling Offer" if self.type == "SellingOffer"
    return "Purchase Offer" if self.type == "PurchaseOffer"
  end

  def currency
    Transaction::CURRENCIES[self.currency_id]
  end

  def update_height!
    transaction = Mastercoin.storage.get_tx(tx_id)
    if transaction
      self.update_attributes(block_height: transaction.get_block.depth)
    end
  end

  def mark_invalid!
    self.update_attribute(:invalid_tx, true)
  end

  # This won't work as long as we can't get the tx in the blockchain
  # We need the sender address to decode the message
  def self.insert_unconfirmed_by_tx(hash)
    tx = Bitcoin::Protocol::Tx.from_hash(hash)
    sending_address = tx.inputs.first.to_hash["prev_out"]["hash"]
    raise tx.inputs.first.previous_output.inspect

    if tx.outputs.collect{|x| x.script.is_multisig?}.include?(true)
      tx.outputs.each do |output|
        if output.script.is_multisig?
          keys = output.script.get_multisig_pubkeys.collect{|x| x.unpack("H*")[0]}
          data = Mastercoin::Message.probe_and_read(keys, sending_address)
        end
      end
    end
  end

  def self.insert_by_tx(tx_hash)
    Rails.logger.info "Looking up tx: #{tx_hash}"
    transaction = Mastercoin.storage.get_tx(tx_hash)
    position = Mastercoin.storage.get_idx_from_tx_hash(tx_hash)
    block = transaction.get_block
    height = block.depth
    time = block.time
    block = nil

    begin
      tx = Mastercoin::Transaction.new(transaction.hash)
      Rails.logger.info "Found tx: #{tx} with type: #{tx.data.transaction_type.to_i.to_s}"
      if tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_SIMPLE_SEND
        unless SimpleSend.find_by(tx_id: transaction.hash).present?
          Rails.logger.info "This is a Mastercoin transaction, do something #{tx_hash} for block #{height}"
          unless a = SimpleSend.create(is_exodus: false, block_height: height, position: position, multi_sig: tx.multisig, address: tx.source_address, block_height: transaction.blk_id, receiving_address: tx.target_address, transaction_type: tx.data.transaction_type, currency_id: tx.data.currency_id, tx_id: transaction.hash, amount: tx.data.amount / 1e8, tx_date: Time.at(time))
            raise "could not save: #{a.inspect}"
          end
        else
          Rails.logger.info "SipmleSend transaction already present."
        end
      elsif tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_SELL_FOR_BITCOIN.to_s
        unless SellingOffer.find_by(tx_id: transaction.hash).present?
          unless a = SellingOffer.create(is_exodus: false, block_height: height, position: position, multi_sig: tx.multisig, address: tx.source_address, block_height: transaction.blk_id, transaction_type: tx.data.transaction_type, currency_id: tx.data.currency_id, tx_id: transaction.hash, amount: tx.data.amount.to_f / 1e8, amount_desired: tx.data.bitcoin_amount.to_f / 1e8, time_limit: tx.data.time_limit, required_fee: tx.data.transaction_fee.to_f / 1e8,  tx_date: Time.at(time))
            raise "could not save: #{a.inspect}"
          end
        else
          Rails.logger.info "Selling offer transaction already present."
        end
      elsif tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_PURCHASE_BTC_TRADE.to_s
        fee = transaction.in.map(&:get_prev_out).map(&:value).sum - transaction.out.map(&:value).sum
        unless PurchaseOffer.find_by(tx_id: transaction.hash).present?
          unless a = PurchaseOffer.create(status: 0,is_exodus: false, block_height: height, position: position, multi_sig: tx.multisig, address: tx.source_address, block_height: transaction.blk_id, bitcoin_fee: fee, transaction_type: tx.data.transaction_type, receiving_address: tx.target_address, currency_id: tx.data.currency_id, tx_id: transaction.hash, amount: tx.data.amount.to_f / 1e8, tx_date: Time.at(time))
            raise "could not save: #{a.inspect}"
          end
        else
          Rails.logger.info "Purchase offer transaction already present."
        end
      else
        raise "We don't know this shit (#{tx.data.transaction_type.to_i.to_s}) #{tx.data.inspect}"
      end
    rescue Mastercoin::Transaction::NoMastercoinTransactionException => e
      Rails.logger.info "Does not look like a mastercoin transaction. Must be exodus payment: #{e}"
    rescue StandardError => e
      Rails.logger.info "Other error found: #{e} #{tx_hash}"
      Rails.logger.info "Backtrace: #{e.backtrace.join("\n")}"
    ensure
      if ExodusTransaction.find_by(tx_id: transaction.hash).present?
        Rails.logger.info "Already have this tx. skipping"
      else
        info = Mastercoin::ExodusPayment.from_transaction(transaction.hash)
        if info.coins_bought.to_f > 0
          a = ExodusTransaction.create(address: Mastercoin::EXODUS_ADDRESS, position: position, block_height: height, receiving_address: info.address, transaction_type: -1, currency_id: 1, tx_id: info.tx.hash, amount: info.total_amount, bonus_amount_included: info.bonus_bought, is_exodus: true, tx_date: Time.at(info.time_included.to_i))
          Rails.logger.info "Added transaction #{a.id} #{a.tx_date}"
        end
      end #end if/else
    end #end being rescu
  end

  # Validation
  def check_transaction_validity
    self.sibling_validations!
    true
  end

  # This is depcrecated; use sibling_validations instead
  def had_funds?
    balance_at = self.get_address.balance(self.currency_id, before_time: self.tx_date)
    balance_at >= amount
  end

  def get_address
    Address.new(self.address)
  end

  def load_transactions
    get_address.load_from_options(self.currency_id, before_block: self.block_height)
  end

  def balance
    get_address.balance(self.currency_id, before_app_position: self.app_position)
  end
  
  def self.calculate_balance(supplied_address)
    transactions = order("app_position ASC")
    Rails.logger.info(transactions.count)
    balance = 0

    transactions.each do |transaction|
      if transaction.type == "ExodusTransaction"
        balance += transaction.amount
      end

      if transaction.type == "SimpleSend"
        if transaction.address == supplied_address
          balance -= transaction.amount
        else
          balance += transaction.amount
        end
      end

      if transaction.type == "PurchaseOffer" && transaction.status == PurchaseOffer::STATUS_SEEN
        if transaction.address == supplied_address 
          balance += transaction.amount
        else
          balance -= transaction.amount
        end
      end
    end

    return balance
  end

  def sibling_validations!
    if balance < self.amount
      self.mark_invalid!
    end
  end
end
