class AddPurchaseOfferMigrationsToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :status, :integer
    add_column :transactions, :reference_transaction_id, :integer
  end
end
