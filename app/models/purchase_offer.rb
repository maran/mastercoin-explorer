class PurchaseOffer < Transaction
  include BitcoinTransaction
  STATUS_NOT_PAID = -1
  STATUS_WAITING = 0
  STATUS_SEEN = 1
  STATUS_CONFIRMED = 2

  belongs_to :selling_offer, foreign_key: :reference_transaction_id

  scope :accepted, -> {where("status > ?", STATUS_WAITING)}

  before_create :set_selling_offer, :set_accepted_amount

  after_create :check_validity
  before_save :set_accepted_amount

  validates :amount, presence: true, numericality: {greater_than: 0}


  def as_json(options = {})
    options.reverse_merge!(methods: [:status_text, :bitcoins_required], include: [:selling_offer])
    super(options)
  end

  def bitcoins_required
    self.accepted_amount * self.selling_offer.price_per_coin
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

  def set_accepted_amount
    if self.amount > self.selling_offer.balance
      self.accepted_amount = self.selling_offer.balance
    else
      self.accepted_amount = self.amount
    end
  end

  def set_selling_offer
    offer = SellingOffer.in_block_for_address(self.block_height, self.receiving_address).before_position(self.position).last
    # We found a offer in the same block as this purchase offer, match it to that.
    if offer.present?
      self.selling_offer = offer
      # We need to go further back to locate the offer
    else
      offer = SellingOffer.height_and_address(self.block_height, self.receiving_address).first
      if offer.present?
        self.selling_offer = offer
      end
    end
  end

  def check_validity
    if self.selling_offer.amount_available < self.amount
      self.mark_invalid!
    end

    if self.bitcoin_fee < self.selling_offer.required_fee
      self.mark_invalid!
    end
  end

  def status_class
    if status == STATUS_WAITING
      "danger"
    elsif status == STATUS_SEEN
      "warning"
    elsif status == STATUS_CONFIRMED
      "success"
    elsif status == STATUS_NOT_PAID 
      "danger"
    end
  end

  def status_text
    if status == STATUS_WAITING
      "Waiting on Payment"
    elsif status == STATUS_SEEN
      "Payment seen"
    elsif status == STATUS_CONFIRMED
      "Payment confirmed"
    elsif status == STATUS_NOT_PAID 
      "Expired, no payment received"
    end
  end
end
