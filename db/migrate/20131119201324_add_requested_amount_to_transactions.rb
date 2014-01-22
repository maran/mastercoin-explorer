class AddRequestedAmountToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :requested_amount, :decimal, precision: 18, scale: 8 
  end
end
