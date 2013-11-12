class AddAppPositionToTransactions < ActiveRecord::Migration
  def change
    add_column :transactions, :app_position, :integer
  end
end
