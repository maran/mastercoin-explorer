class Transactions < ActiveRecord::Migration
  def self.up
    create_table :transactions do |t|
      t.string :address
      t.string :receiving_address
      t.integer :transaction_type
      t.integer :currency_id
      t.string :tx_id
      t.datetime :tx_date
      t.integer :block_height

      # Simple Send
      t.decimal :amount, precision: 18, scale: 8 

      # Exodus
      t.decimal :bonus_amount_included, precision: 18, scale: 8 
      t.boolean :is_exodus, default: true
    end
  end

  def down
    drop_table :transactions
  end
end
