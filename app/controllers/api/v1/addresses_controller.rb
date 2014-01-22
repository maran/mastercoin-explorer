class Api::V1::AddressesController < ApplicationController
  def show
    @address = Address.find_by(name: params[:id])
    render json: @address
  end

  def unspent
    @address = Address.find_by(name: params[:id])
    render json: @address.as_json(include_outputs: true)
  end
end
