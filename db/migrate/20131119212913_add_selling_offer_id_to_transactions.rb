class AddSellingOfferIdToTransactions < ActiveRecord::Migration
  def up
    add_column :transactions, :selling_offer_id, :integer
    Transaction.where("reference_transaction_id IS NOT NULL").each do |tx|
      tx.update_attributes(selling_offer_id: tx.reference_transaction_id, reference_transaction_id: nil)
    end
  end

  def down
    Transaction.where("selling_offer_id IS NOT NULL").each do |tx|
      tx.update_attributes(selling_offer_id: nil, reference_transaction_id: tx.selling_offer_id)
    end
    remove_column :transactions, :selling_offer_id, :integer
  end
end
