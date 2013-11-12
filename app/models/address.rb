class Address
  attr_accessor :address, :sent_transactions, :received_transactions, :exodus_transactions, :received_via_exodus, :balance, :test_balance, :spendable_outputs, :bitcoin_transactions, :sold, :bought, :pending_offers
  def initialize(address)
    self.address = address
  end

  def as_json(options = {})
    self.sent_transactions = self.sent(nil)
    self.received_transactions = self.received(nil)
    self.exodus_transactions = self.exodus_payments(nil)
    self.sold = self.sold(nil)
    self.bought= self.bought(nil)
    self.balance = balance()
    self.test_balance = balance(2)
    self.pending_offers = pending_offers()


    if options.has_key?(:include_outputs)
      self.spendable_outputs = []
      self.bitcoin_transactions  = []

      txouts = Mastercoin.storage.get_txouts_for_address(self.address)
      txouts.each do |txout|
        unless txout.get_next_in
          out_hash = txout.to_hash
          tx = txout.get_tx
          index = tx.outputs.index(txout)
          self.bitcoin_transactions << tx.to_hash unless self.bitcoin_transactions.include?(tx.to_hash)

          self.spendable_outputs << out_hash.merge(:"prev_out" => {:"hash" => tx.hash, :"n" => index})
        end
      end
    end

    super(options)
  end

  def exodus_payments(coin_id = nil)
    if coin_id.present?
      ExodusTransaction.where(receiving_address: self.address).order("tx_date DESC").where(currency_id: coin_id)
    else
      ExodusTransaction.where(receiving_address: self.address).order("tx_date DESC")
    end
  end

  def received(coin_id = nil)
    if coin_id.present?
      SimpleSend.where(receiving_address: self.address).order("tx_date DESC").where(currency_id: coin_id).valid
    else
      SimpleSend.where(receiving_address: self.address).order("tx_date DESC").valid
    end
  end

  def sent(coin_id = nil)
    if coin_id.present?
      SimpleSend.where(address: self.address).order("tx_date DESC").where(currency_id: coin_id).valid
    else
      SimpleSend.where(address: self.address).order("tx_date DESC").valid
    end
  end

  def selling_offer(coin_id=nil)
    if coin_id.present?
      SellingOffer.where(address: self.address).order("tx_date DESC").where(currency_id: coin_id).valid
    else
      SellingOffer.where(address: self.address).order("tx_date DESC").valid
    end
  end

  def bought(coin_id = nil)
    if coin_id.present?
      PurchaseOffer.where(address: self.address).where(currency_id: coin_id).valid.accepted
    else
      PurchaseOffer.where(address: self.address).valid.accepted
    end
  end

  def sold(coin_id = nil)
    ids = selling_offer(coin_id).collect(&:id)
    if ids
      if coin_id.present?
        @sold = PurchaseOffer.where("reference_transaction_id IN (?)", ids).where(currency_id: coin_id).valid.accepted
      else
        @sold = PurchaseOffer.where("reference_transaction_id IN (?)", ids).valid.accepted
      end
    end
    return @sold
  end

  def reserved_amount(coin_id = nil)
    if coin_id.present?
      SellingOffer.where(address: self.address).order("tx_date DESC").where(currency_id: coin_id).valid.current.sum(:amount)
    else
      SellingOffer.where(address: self.address).order("tx_date DESC").valid.current.sum(:amount)
    end
  end

  def pending_offers(coin_id = nil)
    if coin_id.present?
      PurchaseOffer.where(currnecy_id: coin_id).where(address: self.address).order("tx_date DESC")
    else
      PurchaseOffer.where(address: self.address).order("tx_date DESC")
    end
  end

  def load_from_options(coin_id = 1, options = {})
    options.reverse_merge!({in_block: nil, before_time: nil, before_position: nil, before_block: nil})

    @exodus_payments = self.exodus_payments(coin_id)
    @simple_receive= self.received(coin_id)
    @simple_sent = sent(coin_id)
    @sold = sold(coin_id)
    @bought= bought(coin_id)
    @exodus_vesting = 0

    if self.address == "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P"
   #   time_difference = (self.tx_date.to_i - Mastercoin::END_TIME.to_i) / 60 / 60 / 24 / 365.25
   #   @exodus_vesting = (1-(0.5**time_difference)) * 56316.22357622 
    end

    if options[:before_time].present?
      @exodus_payments = @exodus_payments.where("tx_date < ?", options[:before_time])
      @simple_receive = @simple_receive.where("tx_date < ?",options[:before_time])
      @simple_sent = @simple_sent.where("tx_date < ?",options[:before_time])
      @sold = @sold.where("tx_date < ?",options[:before_time])
      @bought = @bought.where("tx_date < ?",options[:before_time])
    elsif options[:before_block].present?
      @exodus_payments = @exodus_payments.where("block_height < ?", options[:before_block])
      @simple_receive = @simple_receive.where("block_height< ?",options[:before_block])
      @simple_sent = @simple_sent.where("block_height< ?",options[:before_block])
      @sold = @sold.where("block_height< ?",options[:before_block])
      @bought = @bought.where("block_height< ?",options[:before_block])
    elsif options[:in_block].present?
      @exodus_payments = @exodus_payments.where(block_height: options[:in_block])
      @simple_receive = @simple_receive.where(block_height: options[:in_block])
      @simple_sent = @simple_sent.where(block_height: options[:in_block])
      @sold = @sold.where(block_height: options[:in_block])
      @bought = @bought.where(block_height: options[:in_block])
    end

    return self
  end

  def balance(currency_id = 1, options ={})
    options.reverse_merge!({in_block: nil, before_block: nil, before_app_position:nil})

    transactions = Transaction.where("address = ? OR receiving_address = ?", self.address, self.address).where(currency_id: currency_id).valid

    if options[:before_app_position]
      transactions = transactions.where("app_position < ?", options[:before_app_position])
    end

    transactions.calculate_balance(self.address)
  end

  def old_balance(coin_id = 1, options = {})
    options.reverse_merge!({in_block: nil, before_time: nil, before_position: nil, before_block: nil})

    @exodus_payments = self.exodus_payments(coin_id)
    @simple_receive= self.received(coin_id)
    @simple_sent = sent(coin_id)
    @sold = sold(coin_id)
    @bought= bought(coin_id)
    @exodus_vesting = 0

#    if self.address == "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P"
   #   time_difference = (self.tx_date.to_i - Mastercoin::END_TIME.to_i) / 60 / 60 / 24 / 365.25
   #   @exodus_vesting = (1-(0.5**time_difference)) * 56316.22357622 
#    end

    if options[:before_time].present?
      @exodus_payments = @exodus_payments.where("tx_date < ?", options[:before_time])
      @simple_receive = @simple_receive.where("tx_date < ?",options[:before_time])
      @simple_sent = @simple_sent.where("tx_date < ?",options[:before_time])
      @sold = @sold.where("tx_date < ?",options[:before_time])
      @bought = @bought.where("tx_date < ?",options[:before_time])
    elsif options[:before_block].present?
      @exodus_payments = @exodus_payments.where("block_height < ?", options[:before_block])
      @simple_receive = @simple_receive.where("block_height< ?",options[:before_block])
      @simple_sent = @simple_sent.where("block_height< ?",options[:before_block])
      @sold = @sold.where("block_height< ?",options[:before_block])
      @bought = @bought.where("block_height< ?",options[:before_block])
    elsif options[:in_block].present?
      @exodus_payments = @exodus_payments.where(block_height: options[:in_block])
      @simple_receive = @simple_receive.where(block_height: options[:in_block])
      @simple_sent = @simple_sent.where(block_height: options[:in_block])
      @sold = @sold.where(block_height: options[:in_block])
      @bought = @bought.where(block_height: options[:in_block])
    end

    rec = @simple_receive.sum(:amount)
    rec_via_exodus = @exodus_payments.sum(:amount)
    sent_amount = @simple_sent.sum(:amount)
    sold = @sold.sum(:amount)
    bought = @bought.sum(:amount)

    #TODO: We should not reducing the sold amount since the total amount is already reserved
    return rec + rec_via_exodus + bought + @exodus_vesting - sent_amount - sold
  end
end
