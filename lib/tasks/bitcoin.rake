namespace :bitcoin do
  task :connect_to_node => :environment do
    Rails.application.eager_load!

    EM.run do
      Bitcoin::Network::CommandClient.connect("127.0.0.1", 9999) do
        on_connected do
          puts "Connected"
          request("monitor", "tx", "block")
        end

        on_block do |block|
          puts "Found block"

          block["tx"].each do |tx|
            handle_tx(tx, true)
          end
        end

        on_tx do |hash|
          handle_tx(hash)
        end

        def handle_tx(hash, via_block = false)
          tx = Bitcoin::Protocol::Tx.from_hash(hash)
          addresses = tx.outputs.collect{|x| x.to_hash(with_address: true)}.collect{|x| x["address"]}
          if addresses.include?("1EXoDusjGwvnjZUyKkxZ4UHEf77z6A5S4P")
            puts "Got exodus payment!: #{hash}"
            if via_block
              puts "Got this via a block so let's add it"
              Transaction.insert_by_tx(tx.hash)
            end
          end
        end
      end
    end
  end

  task :broadcast => :environment do 
    Rails.application.eager_load!

    TransactionQueue.where(sent: false).each do |x|
      x.broadcast
    end
  end
end

