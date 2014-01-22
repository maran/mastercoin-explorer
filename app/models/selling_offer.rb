class SellingOffer < Transaction
  include BitcoinTransaction
  STATUS_ONLY_TEST_ALLOWED = -4

  has_many :purchase_offers, dependent: :destroy
  before_create :set_price_per_coin
  after_create :only_allow_test, :check_transaction_validity

  attr_accessor :public_key

  validates :amount, presence: true, numericality: true
  validates :amount_desired, presence: true, numericality: true
  validates :required_fee, presence: true, numericality: true
  validates :time_limit, presence: true, numericality: {greater_than: 0}

  scope :current, -> { order("app_position DESC").limit(1).first }
  scope :height_and_address, -> height, address { where("block_height < ? AND address = ?", height, address).order("block_height DESC").valid }
  scope :in_block_for_address, -> height, address { where("block_height = ? AND address =?", height, address).order("position ASC").valid }
  scope :before_position, -> position { where("position < ?", position) }

  def as_json(options = {})
    options.reverse_merge!(methods: [:amount_available, :amount_bought])
    super(options)
  end

  def only_allow_test
    if self.currency_id == 1 # Only allow test Coins for now
      self.update_attributes(invalid_tx: true, status: STATUS_ONLY_TEST_ALLOWED)
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

  def amount_available(app_position = nil)
    txs = self.purchase_offers.valid.where("status = ?", PurchaseOffer::STATUS_OPEN)

    if app_position.present?
      txs = txs.where("app_position < ? ", app_position)
    end

    available = self.amount - txs.sum(:accepted_amount)

    txs = self.purchase_offers.valid.where("status = ?", PurchaseOffer::STATUS_CLOSED)
    if app_position.present?
      txs = txs.where("app_position < ? ", app_position)
    end

    available = available - txs.sum(:amount)
      
    return 0 if available < 0
    available
  end

  def amount_bought
    self.purchase_offers.valid.accepted.sum(:amount)
  end

  def set_price_per_coin
    self.price_per_coin = (1 / self.amount)  * self.amount_desired
  end

  def other_offers
    SellingOffer.where(address: self.address).where(currency_id: self.currency_id).valid
  end
end
