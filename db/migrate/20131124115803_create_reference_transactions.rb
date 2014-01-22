class CreateReferenceTransactions < ActiveRecord::Migration
  def change
    create_table :reference_transactions do |t|
      t.integer :transaction_id
      t.decimal :amount, precision: 18, scale: 8 
      t.string :address
      t.string :receiving_address
      t.integer :block_height
      t.datetime :tx_date
      t.integer :currency_id
      t.integer :position

      t.timestamps
    end
  end
end
