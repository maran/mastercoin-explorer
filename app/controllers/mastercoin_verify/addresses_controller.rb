class MastercoinVerify::AddressesController < ApplicationController
  def index
    params[:currency_id] ||= 1
    result = []
    addresses = Transaction.select("distinct(receiving_address)").where(currency_id: params[:currency_id]).collect(&:receiving_address)
    addresses.each do |address|
      if address
        result << {address: address, balance: Address.new(address).balance(params[:currency_id])}
      end
    end
    render json: result
  end
end
