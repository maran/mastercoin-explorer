class PurchaseOffer < Transaction
  include BitcoinTransaction

  STATUS_OFFER_NOT_FOUND = -3 # This transaction is rejected, not found
  STATUS_NOT_ENOUGH_FEE = -2 # This transaction is rejected because the offer didnt have enough fees
  STATUS_SOLD_OUT = -1 # This transaction is rejected because the offer is sold out 

  STATUS_OPEN   = 0 # This transaction can accept new transaction
  STATUS_CLOSED = 1 # This transaction is closed

  belongs_to :selling_offer, foreign_key: :selling_offer_id

  after_create :set_selling_offer_and_amount!

  validates :requested_amount, presence: true, numericality: true

  has_many :reference_transactions, dependent: :destroy, foreign_key: :transaction_id

  scope :accepted, -> { where("amount > 0") }
  scope :pending, -> { where(status: STATUS_OPEN) }

  def as_json(options = {})
    options.reverse_merge!(methods: [:status_text, :bitcoins_required], include: [:selling_offer])
    super(options)
  end

  def bitcoins_required
    if self.selling_offer.present?
      self.accepted_amount * self.selling_offer.price_per_coin
    end
  end

  def has_funds?
    self.calculate_fee
    self.get_transactions

    if self.outputs.blank?
      errors.add(:public_key, "You don't have any Bitcoin funds on your Mastercoin address. Transactions can not be created.")
      return false
    elsif self.outputs.find{|x| BigDecimal.new(x["value"]) > (@fee + @mastercoin_tx)}.blank?
      errors.add(:public_key, "You don't have a big enough output available to create this transaction. Please consolidate some coins and send them to your Mastercoin address.")
      return false
    end
    return true
  end

  def set_selling_offer_and_amount!
    if self.set_selling_offer
      self.set_accepted_amount
      self.check_for_payment!
      self.check_validity
    end

    self.save
  end

  def set_accepted_amount
    # Check how many is left for this selling offer and adjust the amount
    if self.requested_amount > self.selling_offer.amount_available(self.app_position)
      self.accepted_amount = self.selling_offer.amount_available(self.app_position)
    else
      self.accepted_amount = self.requested_amount
    end
  end

  def set_selling_offer
    offer = SellingOffer.where(currency_id: self.currency_id).where(address: self.receiving_address).where("app_position < ?", self.app_position).valid.order("app_position DESC").limit(1).first

    if offer.present?
      self.selling_offer = offer
      return true
    else
      self.invalid_tx = true
      self.status = STATUS_OFFER_NOT_FOUND
      return false
    end
  end

  def check_validity
    if self.selling_offer.amount_available(self.app_position) <= 0
      self.update_attributes(invalid_tx: true, status: STATUS_SOLD_OUT)
    end

    if self.bitcoin_fee < self.selling_offer.required_fee
      self.update_attributes(invalid_tx: true, status: STATUS_NOT_ENOUGH_FEE)
    end
  end

  def status_class
    if status == STATUS_OPEN
      "warning"
    elsif status == STATUS_CLOSED
      "success"
    else
      "danger"
    end
  end

  def status_text
    if status == STATUS_OPEN
      "Waiting on Payment"
    elsif status == STATUS_CLOSED
      "Offer closed"
    elsif status == STATUS_SOLD_OUT
      "Selling offer sold out"
    elsif status == STATUS_NOT_ENOUGH_FEE
      "Did not pay enough fee"
    elsif status = STATUS_OFFER_NOT_FOUND
      "Selling offer not found"
    end
  end

  def check_for_payment!
    self.set_selling_offer unless self.selling_offer.present?
    return false unless self.selling_offer.present?

    return true if Rails.env.to_s == "test"
    tx_ids = []

    head_height = Mastercoin.storage.get_depth
    max_height = (self.block_height + self.selling_offer.time_limit)
    original_height_selling_offer = self.selling_offer.block_height

    # IS THERE A FASTER WAY TO DO THIS?
    outputs = Mastercoin.storage.get_txouts_for_address(self.receiving_address)
    outputs.each do |output|
      tx = output.get_tx
      next if tx_ids.include?(tx.hash)
      tx_ids << tx.hash
      block = tx.get_block
      height = block.depth
      block_time = block.time
      block = nil
      position = Mastercoin.storage.get_idx_from_tx_hash(tx.hash)

      # If this transaction was send before the selling self ignore it
      next if height < original_height_selling_offer
      # If this tranasction was send before the purchase offer ignore it
      next if height <= self.block_height
      # If this transaction was send later then the Purchase self ignore it
      next if height > max_height

      # Collect all transactions to this output and sum them
      # Keep a record of the total paid amount and update it after each block
      # Also redo all statuses

      tx.inputs.each do |input|
        Rails.logger.info "Checking previout ouput for this input: #{input.get_prev_out.to_hash(with_address: true)}"
        if input.get_prev_out.get_address == self.address
          if tx.outputs.collect(&:get_address).include?(Mastercoin::EXODUS_ADDRESS)
            value = BigDecimal.new((output.value / 1e8).to_s).round(8)

            unless Transaction.where(tx_id: tx.hash).count > 0 # Exclude Mastercoin transactions
              Rails.logger.info "Good! This is the address we are looking for"
              reference_transaction = self.reference_transactions.find_or_initialize_by(tx_id: tx.hash)
              reference_transaction.amount = value
              reference_transaction.address = self.address
              reference_transaction.receiving_address = self.receiving_address
              reference_transaction.block_height = height
              reference_transaction.tx_date = block_time
              reference_transaction.position = position
              reference_transaction.currency_id = 0

              if reference_transaction.save
                Rails.logger.info("YEAH!")
              else
                Rails.logger.info("Boe!")
              end
            end
          end
        end
      end
    end

    if head_height > max_height 
      self.status = PurchaseOffer::STATUS_CLOSED
    end # End if height

    self.amount = self.reference_transactions.sum(:amount) / self.selling_offer.price_per_coin
    self.save
  end

  def self.check_for_payments
    PurchaseOffer.where(status: PurchaseOffer::STATUS_OPEN).each do |offer|
      offer.check_for_payment!
    end
  end

    # Monthly chart
  def self.collect_data
    amount_transferred = (Date.parse("2013-10-01")..Date.today).count.times.collect do |x|

      start_date = Time.now
      end_date = start_date-x.day
      purchase_offers = PurchaseOffer.where(status: PurchaseOffer::STATUS_CLOSED).valid.where(currency_id: 2).where("tx_date BETWEEN ? AND ?", end_date, end_date + 1.day)

      if purchase_offers.present?
        total_price_per_day = purchase_offers.sum do |y|
          y.selling_offer.price_per_coin
        end 
        price = (total_price_per_day.to_f/purchase_offers.count)
        data = [end_date.to_i.to_s.ljust(13, "0").to_i , price]
      else
        next
      end
    end
    amount_transferred.compact.reverse
  end
end

