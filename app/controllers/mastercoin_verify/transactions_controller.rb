class MastercoinVerify::TransactionsController < ApplicationController
  def show
    address = params[:id] 
    params[:currency_id] ||= 1
    @transactions = Transaction.select("tx_id, invalid_tx").where("receiving_address = ? OR address = ?", address, address).where(currency_id: params[:currency_id])

    result = {address: address, transactions: []}

    @transactions.each do |tx| 
      result[:transactions] << {tx_hash: tx.tx_id, valid: (!tx.invalid_tx)}
    end

    render json: result
  end
end
