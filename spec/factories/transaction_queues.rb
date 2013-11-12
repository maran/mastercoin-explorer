# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :transaction_queue do
    json_payload "MyText"
    sent false
    sent_at "2013-09-29 13:31:04"
    tx_hash "MyString"
  end
end
