class Address < ActiveRecord::Base
  attr_accessor :spendable_outputs, :bitcoin_transactions, :exodus_time

  has_many :received_transactions, -> { order("app_position DESC") }, foreign_key: "receiving_address", primary_key: "name", class_name: "SimpleSend"
  has_many :sent_transactions, -> { order("app_position DESC") },foreign_key: "address", primary_key: "name", class_name: "SimpleSend"
  has_many :exodus_transactions, -> { order("app_position DESC") },foreign_key: "receiving_address", primary_key: "name"
  has_many :selling_offers, -> { order("app_position DESC") },foreign_key: "address", primary_key: "name"
  has_many :purchase_offers, -> { order("app_position DESC") },foreign_key: "address", primary_key: "name"  

  has_many :bought, ->(address) { order("app_position DESC").valid }, class_name: "PurchaseOffer", foreign_key: "address", primary_key: "name"
  has_many :sold, ->(address) { where("selling_offer_id IN (?)", address.selling_offers.collect(&:id)).valid }, class_name: "PurchaseOffer", primary_key: "name", foreign_key: "receiving_address"

  validates :name, presence: true

  before_save :set_balance

  def as_json(options = {})
    options.reverse_merge!(include: [:sent_transactions, :received_transactions, :exodus_transactions, :selling_offers, :purchase_offers, :bought, :sold], methods: [:pending_offers, :spendable_outputs, :bitcoin_transactions])

    if options.has_key?(:include_outputs)
      self.spendable_outputs = []
      self.bitcoin_transactions  = []

      txouts = Mastercoin.storage.get_txouts_for_address(self.name)
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

  def percentage
    (100 * self.balance / ExodusTransaction.where(currency_id: 1).sum(:amount)).round(2)
  end

  def pending_offers(coin_id = nil)
    if coin_id.present?
      PurchaseOffer.where(currency_id: coin_id).where(address: self.name).order("tx_date DESC").valid
    else
      PurchaseOffer.where(address: self.name).order("tx_date DESC").valid.pending
    end
  end

  # This is always the current balance, the latest one, this can't recalculuate old shit
  # TODO: Rewrite evertyhing to only parse latest state
  def set_balance
    self.reserved_balance = self.selling_offers.real.valid.current.amount if self.selling_offers.valid.real.any?
    self.reserved_test_balance = self.selling_offers.test.valid.current.amount if self.selling_offers.valid.test.any?

    self.balance = self.calculate_balance - self.reserved_balance

    if self.name == "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P" && self.exodus_time
      time_difference = (exodus_time.to_i - Mastercoin::END_TIME.to_i) / 31556926.0
      self.balance += ((1-(0.5**time_difference)) * BigDecimal.new("56316.23576222")).round(8)
    end

    self.test_balance = self.calculate_balance(2) - self.reserved_test_balance
  end

  def get_transactions(currency_id = 2)
    Transaction.where("address = ? OR receiving_address = ?", self.name, self.name).where(currency_id: currency_id).valid.order("app_position ASC")
  end

  def calculate_balance(currency_id = 1, options ={}) #  This was the old 'balance' method, which is now an attribute
    options.reverse_merge!({in_block: nil, before_block: nil, exodus_time: nil, before_app_position:nil, parent: nil})

    transactions = Transaction.where("address = ? OR receiving_address = ?", self.name, self.name).where(currency_id: currency_id).valid.order("app_position ASC")

    if options[:before_app_position]
      transactions = transactions.where("app_position < ?", options[:before_app_position])
    end

    transactions.calculate_balance(self.name, options)
  end
end
