class AddPositionToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :position, :integer
  end
end
