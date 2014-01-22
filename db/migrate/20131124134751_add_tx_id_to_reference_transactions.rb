class AddTxIdToReferenceTransactions < ActiveRecord::Migration
  def change
    add_column :reference_transactions, :tx_id, :string
  end
end
