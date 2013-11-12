class AddSellingOfferToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :amount_desired, :decimal, precision: 18, scale: 8 
    add_column :transactions, :time_limit, :integer
    add_column :transactions, :required_fee, :decimal, precision: 18, scale: 8 
    add_column :transactions, :price_per_coin, :decimal, precision: 18, scale: 8 
  end
end
