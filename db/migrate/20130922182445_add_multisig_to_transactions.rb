class AddMultisigToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :multi_sig, :boolean, default: false
  end
end
