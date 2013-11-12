class AddAcceptedAmountToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :accepted_amount, :decimal, precision: 18, scale: 8 
  end
end
