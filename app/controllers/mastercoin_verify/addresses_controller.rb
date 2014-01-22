class MastercoinVerify::AddressesController < ApplicationController
  def index
    result = Address.all.collect do |address|
      if params[:currency_id].to_s == "2"
        {address: address.name, balance: address.test_balance}
      else
        {address: address.name, balance: address.balance}
      end
    end
    render json: result
  end
end
