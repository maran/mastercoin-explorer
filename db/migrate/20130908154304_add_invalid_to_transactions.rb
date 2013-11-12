class AddInvalidToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :invalid_tx, :boolean, default: false
  end
end
