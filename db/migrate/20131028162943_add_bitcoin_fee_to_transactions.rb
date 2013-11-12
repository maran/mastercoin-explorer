class AddBitcoinFeeToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :bitcoin_fee, :decimal, precision: 18, scale: 8
  end
end
