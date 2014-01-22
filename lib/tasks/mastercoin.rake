namespace :mastercoin do

  task :recalculate_position => :environment do
    Rails.application.eager_load!
    Transaction.order("block_height ASC, position ASC").each_with_index do |x, y|
      x.app_position = y + 1
      x.save
    end
  end

  task :recalculate_missing_origin => :environment do
    Rails.application.eager_load!
    Transaction.where(address: nil).collect do |transaction|
      tx = transaction.tx_id 
      transaction.destroy
      tx
    end.each do |tx|
      Transaction.insert_by_tx(tx)
    end
  end

  task :recalculate_block_height => :environment do
    Rails.application.eager_load!
    Transaction.limit(20).each do |transaction|
      transaction.update_height!
    end
  end

  task :check_for_invalid => :environment do
    Rails.application.eager_load!
    SimpleSend.valid.each do |transaction|
      transaction.check_transaction_validity
    end
  end

  task :check_purchases => :environment do
    PurchaseOffer.check_for_payments
  end

  task :parse_exodus => :environment do
    Rails.application.eager_load!
    store = Mastercoin.storage
    txouts = store.get_txouts_for_address(Mastercoin::EXODUS_ADDRESS)
    puts "Parsing #{txouts.length} Exodus outputs"
    txouts.each do |txout|
      transaction = txout.get_tx
      Transaction.insert_by_tx(transaction.hash)
    end
  end
end
