require 'eventmachine'
require 'bitcoin'
require 'socket'
class Bitcoin::Protocol::Parser; def log; stub=Object.new; def stub.method_missing(*a); end; stub; end; end


module MastercoinNode
  class Relayer < EM::Connection

    # We could try processing transactions here
    def on_block(block)
      block["tx"].each do |tx|
        on_tx(tx)
      end
    end

    def on_handshake_complete
      return if @connected
      @connected = true
      puts "Relayer connected"
      Rails.logger.info("Relayer connected")
      EM.add_periodic_timer(20) do 
        check_for_new_transactions
      end
    end

    def check_for_new_transactions
      Rails.logger.info("Checking for new transactions: #{TransactionQueue.where(sent: false).count}")
    end

    def on_get_block(hash); end
    def on_addr(addr); end
    def on_inv_transaction(hash);end
    def on_inv_block(hash);end

    def on_handshake_begin
      version = Bitcoin::Protocol::Version.new({
        :user_agent => "/Satoshi:0.8.1/",
        :last_block => 0,
        :from       => "127.0.0.1:#{Bitcoin.network[:default_port]}",
        :to         => "#{@host}:#{@port}",
      })
      send_data(version.to_pkt)
    end

    def on_connected
      request("monitor", "block", "tx")
    end

    def on_version(version)
      @version ||= version
      send_data( Bitcoin::Protocol.verack_pkt )
      on_handshake_complete
    end

    def initialize(host, port, node=nil, opts={})
      set_host(host, port)
      @node   = node
      @parser = Bitcoin::Protocol::Parser.new( self )
    end

    def receive_data(data); @parser.parse(data); end
    def post_init; on_handshake_begin; end
    def unbind; end
    def set_host(host, port=8333); @host, @port = host, port; end

    def hth(h); h.unpack("H*")[0]; end
    def htb(h); [h].pack("H*"); end


    def self.connect(host, port, *args)
      EM.connect(host, port, self, host, port, *args)
    end

    def self.connect_random_from_dns(seeds=[], count=1, *args)
      seeds = Bitcoin.network[:dns_seeds] unless seeds.any?
      if seeds.any?
        seeds.sample(count).map{|dns|
          host = IPSocket.getaddress(dns)
          connect(host, Bitcoin.network[:default_port], *args)
        }
      else
        raise "No DNS seeds available. Provide IP, configure seeds, or use different network."
      end
    end

    def self.connect_known_nodes(count=1)
      connect_random_from_dns(Bitcoin.network[:known_nodes], count)
    end
  end
end
