# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :reference_transaction do
    transaction_id 1
    amount "9.99"
    address "MyString"
    receiving_address "MyString"
    block_height 1
    tx_date "2013-11-24 12:58:06"
    currency_id 1
    position 1
  end
end
