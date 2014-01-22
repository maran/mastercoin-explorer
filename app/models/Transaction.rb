class Transaction < ActiveRecord::Base
  class CouldNotSaveTransactionException < StandardError;end;

  CURRENCIES = {
    0 => "BTC",
    1 => "MSC",
    2 => "Test MSC",
  }

  acts_as_list column: :app_position

  scope :real, -> { where(currency_id: 1) }
  scope :test, -> { where(currency_id: 2) }
  scope :valid, -> { where(invalid_tx: false) }

  after_save :persist_address
  after_create :set_app_position!

  def persist_address
    begin
      address = Address.find_or_initialize_by(name: self.address)
      address.save

      address = Address.find_or_initialize_by(name: self.receiving_address)
      address.save
    rescue ActiveRecord::StatementInvalid
      Rails.logger.info("SOMETHING WENT WRONG WITH: #{self}")
    end
  end

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

  def self.reimport_last_transactions(amount = 100, offset = 0)
    txouts = Mastercoin.storage.get_txouts_for_address(Mastercoin::EXODUS_ADDRESS)
    txs = txouts.collect(&:get_tx)
    txs[offset..offset+amount].each do |tx|
      Transaction.insert_by_tx(tx.hash)
    end
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
    translogger = Logger.new(Rails.root + 'log/transaction_import.log')
    translogger.info "Looking up tx: #{tx_hash}"
    transaction = Mastercoin.storage.get_tx(tx_hash)
    position = Mastercoin.storage.get_idx_from_tx_hash(tx_hash)
    block = transaction.get_block
    height = block.depth
    time = block.time
    block = nil

    begin
      tx = Mastercoin::Transaction.new(transaction.hash)
      translogger.info "Found tx: #{tx} with #{tx.to_s} in block #{height}"
      source_address = tx.source_address

      if tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_SIMPLE_SEND
        unless SimpleSend.find_by(tx_id: transaction.hash).present?
          simple_send = SimpleSend.new(is_exodus: false, position: position, multi_sig: tx.multisig, receiving_address: tx.target_address, transaction_type: tx.data.transaction_type, currency_id: tx.data.currency_id, tx_id: transaction.hash, amount: tx.data.amount / 1e8, tx_date: Time.at(time))
          simple_send.address = source_address
          simple_send.block_height = height
          unless simple_send.save
            raise CouldNotSaveTransactionException.new "Could not save transaction: #{simple_send.inspect}"
          end
        end
      elsif tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_SELL_FOR_BITCOIN.to_s
        unless SellingOffer.find_by(tx_id: transaction.hash).present?
          a = SellingOffer.new(is_exodus: false, position: position, multi_sig: tx.multisig, address: tx.source_address, transaction_type: tx.data.transaction_type, currency_id: tx.data.currency_id, tx_id: transaction.hash, amount: tx.data.amount.to_f / 1e8, amount_desired: tx.data.bitcoin_amount.to_f / 1e8, time_limit: tx.data.time_limit, required_fee: tx.data.transaction_fee.to_f / 1e8,  tx_date: Time.at(time))
          a.block_height = height
          unless a.save
            raise CouldNotSaveTransactionException.new "Could not save transaction: #{a.inspect}"
          end
        else
          translogger.info "Selling offer transaction already present."
        end
      elsif tx.data.transaction_type.to_i.to_s == Mastercoin::TRANSACTION_PURCHASE_BTC_TRADE.to_s
        fee = transaction.in.map(&:get_prev_out).map(&:value).sum - transaction.out.map(&:value).sum
        unless PurchaseOffer.find_by(tx_id: transaction.hash).present?
          a = PurchaseOffer.new(status: 0,is_exodus: false, position: position, multi_sig: tx.multisig, address: tx.source_address, bitcoin_fee: fee, transaction_type: tx.data.transaction_type, amount: 0, receiving_address: tx.target_address, currency_id: tx.data.currency_id, tx_id: transaction.hash, requested_amount: tx.data.amount.to_f / 1e8, tx_date: Time.at(time))
          a.block_height = height
          unless a.save
            raise CouldNotSaveTransactionException.new "Could not save transaction: #{a.inspect}"
          end
        else
          translogger.info "Purchase offer transaction already present."
        end
      else
        raise "We don't know this shit (#{tx.data.transaction_type.to_i.to_s}) #{tx.data.inspect}"
      end
    rescue Mastercoin::Transaction::NoMastercoinTransactionException => e
      translogger.info "Does not look like a mastercoin transaction. #{e}"
    rescue CouldNotSaveTransactionException => e
      ExceptionNotifier.notify_exception(e)
    rescue StandardError => e
      translogger.info "Other error found: #{e} #{tx_hash}"
      translogger.info "Backtrace: #{e.backtrace.join("\n")}"
      ExceptionNotifier.notify_exception(e)
    ensure
      # Rewrite this part plox
      if ExodusTransaction.find_by(tx_id: transaction.hash).present?
        translogger.info "Already have this tx. skipping"
      else
        info = Mastercoin::ExodusPayment.from_transaction(transaction.hash)
        if info.coins_bought.to_f > 0
          a = ExodusTransaction.new(address: Mastercoin::EXODUS_ADDRESS, position: position, receiving_address: info.address, transaction_type: -1, currency_id: 1, tx_id: info.tx.hash, amount: info.total_amount, bonus_amount_included: info.bonus_bought, is_exodus: true, tx_date: Time.at(info.time_included.to_i))
          a.block_height = height
          a.save
          translogger.info "Added transaction #{a.id} #{a.tx_date}"
        end
      end #end if/else
    end #end being rescu
  end

  # Validation
  def check_transaction_validity
    self.sibling_validations!
    true
  end

  def get_address
    address = Address.find_or_initialize_by(name: self.address)
    address.save if address.new_record?

    return address
  end

  def balance
    balance_amount = get_address.calculate_balance(self.currency_id, before_app_position: self.app_position, exodus_time: self.tx_date, parent: self)
    return balance_amount
  end
  
  def self.calculate_balance(supplied_address, options = {})
    transactions = order("app_position ASC")

    # If we want to overwrite a previous selling order we shouldn't use the reserved balance before this block; but of this actual block.
    if options[:parent] && options[:parent].type == "SellingOffer"
      latest_selling_offer = options[:parent]
    else
      latest_selling_offer = transactions.where(type: "SellingOffer").order("app_position DESC").first
    end

    balance = 0
    reserved = 0

    if options[:exodus_time]
      if supplied_address == "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P"
        time_difference = (options[:exodus_time].to_i - Mastercoin::END_TIME.to_i) / 31556926.0
        balance = ((1-(0.5**time_difference)) * BigDecimal.new("56316.23576222")).round(8)
      end
    end

    transactions.each do |transaction|
      if transaction.type == "ExodusTransaction"
        unless supplied_address == "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P"
          balance += transaction.amount
        end
      end

      # The && Statement is to ignore transaction that send funds to themselves for balance calculations.
      if transaction.type == "SimpleSend" && transaction.address != transaction.receiving_address
        if transaction.address == supplied_address
          balance -= transaction.amount
        else
          balance += transaction.amount
        end
      end

      #TODO: ADD THIS AGAIN
      #if transaction.type == "SellingOffer"
      #  # Only the latest open selling offer should be reserved, nothing else
      #  if transaction.address == supplied_address && latest_selling_offer == transaction
      #    balance -= transaction.amount
      #    reserved += transaction.amount
      #  end
      #end

      if transaction.type == "PurchaseOffer"
        if transaction.address == supplied_address 
          balance += (transaction.amount || 0)
        else
          reserved -= (transaction.amount || 0)
        end
      end
    end

    if options[:reserved]
      return balance, reserved
    else
      return balance
    end
  end

  def sibling_validations!
    unless self.type == ExodusTransaction
      self.validate_balance!
    end

    # Scans through the msc blockchain and flag every transaction we need to rescan
    self.revalidate_children

    # Now let's validate them all
    validation_transactions = Transaction.where(revalidate: true)

    Rails.logger.info("Revalidating #{validation_transactions.count} transactions")
    # Let's do it!
    validation_transactions.each(&:validate_balance!)
  end

  def validate_balance!
    if balance < self.amount
      self.mark_invalid!
    end
    self.update_attributes(revalidate: false)

    #TODO: HACK, THIS SHOULD BE REWRITTEN SOMEHOW
    if self.type == "PurchaseOffer"
      self.set_selling_offer_and_amount!
      self.save
    end
  end

  def revalidate_children
    puts "SELFIE: #{self.address} - #{self.receiving_address}"
    if self.type == "ExodusTransaction"
      txs = Transaction.where("address = ?",self.receiving_address)
    else
      txs = Transaction.where("(address = ? AND type = 'SellingOffer') OR (address = ? AND type ='SimpleSend') OR (receiving_address = ? AND type = 'PurchaseOffer')", self.address, self.address, self.address)
    end

    txs.where("app_position > ?", self.app_position).order("app_position ASC").where(revalidate: false).each do |tx|
      tx.update_attributes(invalid_tx: false, revalidate: true, status: 0)
      tx.revalidate_children
    end
  end

  def self.reimport!
    order("app_position ASC").each(&:reimport!)
  end

  def reimport!
    hash = self.tx_id
    self.destroy
    Transaction.insert_by_tx(hash)
  end
end
