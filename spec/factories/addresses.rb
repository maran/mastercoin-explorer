# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :address do
    balance "9.99"
    test_balance "9.99"
    reserved_balance "9.99"
    reserved_test_balance "9.99"
  end
end
