class ChangeForMultipleRelay < ActiveRecord::Migration
  def change
    add_column :transaction_queues, :sent_blockchain, :boolean, default: false
    add_column :transaction_queues, :sent_eligius, :boolean, default: false
  end
end
