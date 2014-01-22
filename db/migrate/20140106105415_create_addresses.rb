class CreateAddresses < ActiveRecord::Migration
  def change
    create_table :addresses do |t|
      t.string :name
      t.decimal :balance, precision: 18, scale: 8, default: 0
      t.decimal :test_balance, precision: 18, scale: 8, default: 0
      t.decimal :reserved_balance, precision: 18, scale: 8, default: 0
      t.decimal :reserved_test_balance, precision: 18, scale: 8, default: 0

      t.timestamps
    end
  end
end
