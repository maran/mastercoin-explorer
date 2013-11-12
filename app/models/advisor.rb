class Advisor
  include ActiveModel::Validations
  include ActiveModel::Model
  include ActiveModel::Conversion
  extend ActiveModel::Naming
  include BitcoinTransaction
  attr_accessor :currency_id, :transaction_type, :amount, :receiving_address
  attr_accessor :advice_object
  attr_accessor :public_key, :sending_address
  attr_accessor :transaction_hash

  attr_accessor :btc_amount
  attr_accessor :time_limit
  attr_accessor :transaction_fee

#  validates :amount, numericality: {greater_than: 0}, presence: true
#  validates :currency_id, presence: true
#  validates :transaction_type, presence: true
#  validates :receiving_address, presence: true
#  validates :public_key, presence: true
#
  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def persisted?
    false
  end
end
