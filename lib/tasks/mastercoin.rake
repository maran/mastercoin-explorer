namespace :mastercoin do

  task :recalculate_position => :environment do
    Rails.application.eager_load!
    Transaction.order("block_height ASC, position ASC").each_with_index do |x, y|
      x.app_position = y + 1
      x.save
    end
  end

  task :check_for_invalid => :environment do
    Rails.application.eager_load!
    SimpleSend.valid.each do |transaction|
      transaction.check_transaction_validity
    end
  end

  task :check_purchases => :environment do
    PurchaseOffer.where(status: PurchaseOffer::STATUS_WAITING).each do |offer|
      offer.update_height! # WHY ARE WE GETTING WRONG BLOCK HEIGHTS
      offer.selling_offer.update_height!

      head_height = Mastercoin.storage.get_depth
      max_height = (offer.block_height + offer.selling_offer.time_limit)
      original_height_selling_offer = offer.selling_offer.block_height

      # IS THERE A FASTER WAY TO DO THIS?
      outputs = Mastercoin.storage.get_txouts_for_address(offer.receiving_address)
      outputs.each do |output|
        tx = output.get_tx

        puts "Checking inputs for tx - #{tx.hash}"
        height = tx.get_block.depth
        puts "This transaction had a block height of #{height}. The Selling Offer was made in block #{original_height_selling_offer}. The latest block the transaction can be in is #{max_height}"

        # If this transaction was send before the selling offer ignore it
        next if height < original_height_selling_offer
        puts "Good! Send after selling order"
        # If this transaction was send later then the Purchase offer ignore it
        next if height > max_height
        puts "Good! Transaction was before the max height"

        tx.inputs.each do |input|
          puts "Checking previout ouput for this input: #{input.get_prev_out.to_hash(with_address: true)}"
          if input.get_prev_out.get_address == offer.address
                puts "Good! This is the address we are looking for"
            value = BigDecimal.new(output.value)
            if value >= offer.bitcoins_required.round(8) * 1e8
                puts "Good! The correct value is send"
              if tx.outputs.collect(&:get_address).include?(Mastercoin::EXODUS_ADDRESS)
                puts "Woop everything is good"
                offer.update_attributes(status: PurchaseOffer::STATUS_CONFIRMED)
              else
                puts "Sadly this tx doesn't have an exodus output"
              end
            else
                puts "Bad! We expected #{offer.bitcoins_required * 1e8} but we got #{value} instead!"
            end
          end
        end
      end

      if head_height > max_height && offer.status == PurchaseOffer::STATUS_WAITING
        puts "Expired payment"
        offer.update_attributes(status: PurchaseOffer::STATUS_NOT_PAID, invalid_tx: true)
      end # End if height
    end
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
