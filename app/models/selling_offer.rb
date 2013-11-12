class SellingOffer < Transaction
  include BitcoinTransaction

  has_many :purchase_offers, foreign_key: :reference_transaction_id
  before_save :set_price_per_coin
  after_create :set_current

  attr_accessor :public_key

  #validates :amount, presence: true, numericality: {greater_than: 0}
  #validates :amount_desired, presence: true, numericality: {greater_than: 0}
  #validates :required_fee, presence: true, numericality: {greater_than_or_equal_to: 0}
  #validates :time_limit, presence: true, numericality: {greater_than: 0}

  scope :current, -> { where(current: true).limit(1) }
  scope :height_and_address, -> height, address { where("block_height < ? AND address = ?", height, address).order("block_height DESC").valid }
  scope :in_block_for_address, -> height, address { where("block_height = ? AND address =?", height, address).order("position ASC").valid }
  scope :before_position, -> position { where("position < ?", position) }

  def as_json(options = {})
    options.reverse_merge!(methods: [:amount_available, :amount_bought])
    super(options)
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

  def amount_available
    amount_for_sale = self.amount - self.amount_bought
  end

  def amount_bought
    self.purchase_offers.valid.accepted.sum(:amount)
  end

  def set_price_per_coin
    self.price_per_coin = (1 / self.amount)  * self.amount_desired
  end

  # This is only used on our frontpage, should not be used for matching orders
  def set_current
    offers = SellingOffer.where(address: self.address).where(currency_id: self.currency_id).valid.order("tx_date DESC, position DESC")
    current_offer = offers.first
    if offers.update_all(current: false)
      current_offer.update_attributes(current: true)
    end
  end
end
