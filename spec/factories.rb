FactoryGirl.define do
  factory :purchase_offer do
    address "2VV1234pyQpW3sqZbfAWhSRiVeeN552BXQ"
    receiving_address "1KA9SV5pyqpW3sqZbfAWhSRiVeeN552BXQ"
    currency_id 1
    amount 10
    tx_date "2013-09-01 23:39:30"
    block_height 16
    position 5
    bitcoin_fee 0.0001
    status 1
  end

  factory :selling_offer do
    address "1KA9SV5pyqpW3sqZbfAWhSRiVeeN552BXQ"
    currency_id 1
    amount 10
    tx_date "2013-09-01 23:39:30"
    block_height 15
    position 5
    amount_desired 0.001
    time_limit 6
    required_fee 0.0001
  end

  factory :exodus_transaction do
    address "1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P"
    receiving_address "1KA9SV5pyqpW3sqZbfAWhSRiVeeN552BXQ"
    transaction_type -1
    currency_id 1
    is_exodus true
    amount 10
    bonus_amount_included 1
    tx_date "2013-08-01 22:39:30"
    block_height 4
    position 8
  end

  # This will use the User class (Admin would have been guessed)
  factory :simple_send do
    address "1KA9SV5pyqpW3sqZbfAWhSRiVeeN552BXQ"
    receiving_address "1Cu3gkevrm5bAJAWabwiWMWw8DsVujDbMD"
    transaction_type 0
    currency_id 1
    amount 10
    tx_date "2013-08-01 23:39:30"
    block_height 5
    position 5
  end

  factory :receiving_simple_send, class: "SimpleSend" do
    address "1Cu3gkevrm5bAJAWabwiWMWw8DsVujDbMD"
    receiving_address "1KA9SV5pyqpW3sqZbfAWhSRiVeeN552BXQ"
    transaction_type 0
    currency_id 1
    amount 10
    tx_date "2013-08-01 23:39:30"
    block_height 5
    position 5
    before(:create) do |simple_send|
      FactoryGirl.create(:exodus_transaction, receiving_address: simple_send.address)
    end
  end
end
