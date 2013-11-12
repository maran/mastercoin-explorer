class Api::V1::AddressesController < ApplicationController
  def show
    @address = Address.new(params[:id])
    render json: @address
  end

  def unspent
    @address = Address.new(params[:id])
    render json: @address.as_json(include_outputs: true)
  end
end
