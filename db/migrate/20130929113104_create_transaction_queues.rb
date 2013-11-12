class CreateTransactionQueues < ActiveRecord::Migration
  def change
    create_table :transaction_queues do |t|
      t.text :json_payload
      t.boolean :sent, default: false
      t.datetime :sent_at
      t.string :tx_hash

      t.timestamps
    end
  end
end
