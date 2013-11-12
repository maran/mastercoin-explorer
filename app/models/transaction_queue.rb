class TransactionQueue < ActiveRecord::Base
  validates :tx_hash, presence: true, uniqueness: true
  validates :json_payload, presence: true
  
  def broadcast
    Rails.logger.info("Checking tx ##{self.id} - #{self.tx_hash}")
    puts("Checking tx ##{self.id} - #{self.tx_hash}")

    tx = Bitcoin::P::Tx.from_json(self.json_payload)
    raw = tx.to_payload.unpack("H*").first
  #  send_data(Bitcoin::Protocol.pkt('tx', tx.to_payload))

    self.sent = true
    self.sent_at = Time.now

    begin
      eligius = RestClient.post 'http://eligius.st/~wizkid057/newstats/pushtxn.php', {transaction: raw, send: "Push"}
      self.sent_eligius = true
    rescue RestClient::InternalServerError, RestClient::RequestTimeout => e
      Rails.logger.info("Error while posting to Eligius: #{e}.")
    rescue StandardError => e
      Rails.logger.info("Unknown error while posting to Eligius: #{e}.")
    end


    begin
      blockchain = RestClient.post 'https://blockchain.info/pushtx', {tx: raw}
      self.sent_blockchain = true
    rescue RestClient::InternalServerError, RestClient::RequestTimeout => e
      Rails.logger.info("Error while posting to blockchain: #{e}.")
    rescue StandardError => e
      Rails.logger.info("Unknown error while posting to Blockchain: #{e}.")
    end

    self.save
  end
end
