# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
#
so = SellingOffer.create(amount: 1000, required_fee: 0.0001,  time_limit: 10, amount_desired: 10, block_height: 10, position: 1, tx_date: Time.now - 5.days)
so2 = SellingOffer.create(amount: 1000, required_fee: 0.0001, time_limit: 10, amount_desired: 15, block_height: 10, position: 1, tx_date: Time.now - 5.days)
so3 = SellingOffer.create(amount: 1000, required_fee: 0.0001, time_limit: 10, amount_desired: 20, block_height: 10, position: 1, tx_date: Time.now - 5.days)

start = Date.parse("2013-10-01")
end_date = start + 7.days

i = 15

(start..end_date).each do |day|
  buy = PurchaseOffer.new(amount: 10, status: 1, tx_date: day, block_height: i, selling_offer: so, bitcoin_fee: 0.01)
  buy.update_attribute(:invalid_tx, false)
  i += 1
end

start = end_date 
end_date = start + 1.week

(start..end_date).each do |day|
  buy = PurchaseOffer.new(amount: 10, status: 1, tx_date: day, block_height: i, selling_offer: so2, bitcoin_fee: 0.01)
  buy.update_attribute(:invalid_tx, false)
end

start = end_date
end_date = start + 1.week

(start..end_date).each do |day|
  buy = PurchaseOffer.new(amount: 10, status: 1, tx_date: day, block_height: i, selling_offer: so3, bitcoin_fee: 0.01)
  buy.update_attribute(:invalid_tx, false)
end

start = end_date
end_date = start + 1.week

(start..end_date).each do |day|
  buy = PurchaseOffer.new(amount: 10, status: 1, tx_date: day, block_height: i, selling_offer: so2, bitcoin_fee: 0.01)
  buy.update_attribute(:invalid_tx, false)
end

start = end_date
end_date = start + 1.week

(start..end_date).each do |day|
  buy = PurchaseOffer.new(amount: 10, status: 1, tx_date: day, block_height: i, selling_offer: so3, bitcoin_fee: 0.01)
  buy.update_attribute(:invalid_tx, false)
end
