class AddPaymentTxIdToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :payment_tx_id, :string
  end
end
