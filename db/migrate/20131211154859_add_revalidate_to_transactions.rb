class AddRevalidateToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :revalidate, :boolean, default: false
  end
end
