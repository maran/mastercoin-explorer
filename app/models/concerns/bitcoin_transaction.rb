module BitcoinTransaction
  extend ActiveSupport::Concern
  attr_accessor :bitcoin_transactions, :outputs, :sending_address, :transaction_hash, :public_key, :forced_fee
  include Bitcoin::Builder

  def calculate_fee
    if self.forced_fee
      @fee = BigDecimal.new(self.forced_fee)
    else
      @fee = BigDecimal.new("0.0001")
    end

    if @fee < 0.0001
      @fee = BigDecimal.new("0.0001")
    end

    @tx_amount = BigDecimal.new("0.00006")
    @mastercoin_tx = (4 * @tx_amount)
  end

  def has_funds
    self.calculate_fee
    self.get_transactions


    if self.outputs.blank?
      errors.add(:amount, "You don't have any Bitcoin funds on your Mastercoin address. Transactions can not be created.")
    elsif self.outputs.find{|x| BigDecimal.new(x["value"]) > (@fee + @mastercoin_tx)}.blank?
      errors.add(:amount, "You don't have a big enough output available to create this transaction. Please consolidate some coins and send them to your Mastercoin address.")
    end
  end


  def get_transactions
    self.bitcoin_transactions ||= []
    self.outputs ||= []
    begin
      self.sending_address = Bitcoin::Key.new(nil, self.public_key).addr
    rescue OpenSSL::PKey::EC::Point::Error, OpenSSL::BNError => e
      errors.add(:pulic_key, "Not a valid public key")
    end

    outputs = Mastercoin.storage.get_txouts_for_address(self.sending_address)
    outputs.each do |output|
      unless output.get_next_in # not spend
        out_hash = output.to_hash
        tx = output.get_tx
        index = tx.outputs.index(output)
        self.bitcoin_transactions << tx.to_hash unless self.bitcoin_transactions.include?(tx.to_hash)
        self.outputs << out_hash.merge(:"prev_out" => {:"hash" => tx.hash, :"n" => index})
      end
    end
  end

  def create_purchase_offer
    self.get_transactions
    self.calculate_fee

    @data_keys = [Mastercoin::PurchaseOffer.new(currency_id: 2, amount: self.amount.to_f * 1e8).encode_to_compressed_public_key(self.sending_address)]
    Rails.logger.info("DATA KEYS: #{@data_keys}")

    send_tx
  end

  def create_selling_offer
    self.get_transactions
    self.calculate_fee
    @data_keys = Mastercoin::SellingOffer.new(currency_id: 2, amount: self.amount.to_f * 1e8, bitcoin_amount: self.amount_desired.to_f * 1e8, time_limit: self.time_limit, transaction_fee: self.required_fee.to_f * 1e8).encode_to_compressed_public_key(self.sending_address) 
    Rails.logger.info("DATA KEYS: #{@data_keys}")

    send_tx(false)
  end

  def send_simple_send
    self.get_transactions
    self.calculate_fee
    @data_keys = Mastercoin::SimpleSend.new(currency_id: self.currency_id, amount: self.amount.to_f * 1e8).encode_to_compressed_public_key(self.sending_address)

    send_tx
  end
  
  def send_tx(receiving = true)
    @data_keys.insert(0, self.public_key)

    output = self.outputs.find{|x| BigDecimal.new(x["value"]) > (@fee + @mastercoin_tx)}

    @change_amount = BigDecimal.new(output["value"]) - @fee - @mastercoin_tx

    tx = self.bitcoin_transactions.find{|x| x["hash"] == output[:prev_out][:hash]}
    if tx.is_a?(Array)
      tx = tx[0]
    end

    tx = build_tx do |t|
      t.input do |i|
        i.prev_out Bitcoin::Protocol::Tx.from_hash(tx)
        i.prev_out_index output[:prev_out][:n] 
      end

      # Change address
      t.output do |o|
        o.value @change_amount * 1e8

        o.script do |s|
          s.type :address
          s.recipient self.sending_address
        end
      end

      if receiving
        # Receiving address
        t.output do |o|
          o.value @tx_amount * 1e8

          o.script do |s|
            s.type :address
            s.recipient self.receiving_address
          end
        end
      end

      # Exodus address
      t.output do |o|
        o.value @tx_amount * 1e8

        o.script do |s|
          s.type :address
          s.recipient Mastercoin::EXODUS_ADDRESS
        end
      end

      # Data address
      t.output do |o|
        o.value (@tx_amount) * 1e8 * 2

        o.script do |s|
          s.type :multisig
          s.recipient 1, *@data_keys
        end
      end
    end

    tx = Bitcoin::Protocol::Tx.new( tx.to_payload )

    self.transaction_hash = tx.to_payload.unpack("H*").first

    #  Bitcoin::Protocol::Tx.new([key].pack("H*")) <= reverse the bitcoind to ruby code
    Rails.logger.info("If you want to send it by Bitcoind use this")
    Rails.logger.info(transaction_hash)
    Rails.logger.info("Required fee: #{tx.calculate_minimum_fee} - Multisig size: #{tx.outputs.last.script.bytesize}")
  end

end
