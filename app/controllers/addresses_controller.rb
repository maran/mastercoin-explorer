class AddressesController < ApplicationController
  def index
    @addresses = Address.order("balance DESC").limit(50)
  end
  
  def show
    @address = Address.find_by(name: params[:id])
    unless @address
      redirect_to root_path, notice: "Address not found."
    end
  end
end
