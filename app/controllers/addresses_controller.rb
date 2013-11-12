class AddressesController < ApplicationController
  def index
    b = []
    total = ExodusTransaction.where(currency_id: 1).sum(:amount)
    Transaction.where(invalid_tx: false).select("distinct(receiving_address)").collect(&:receiving_address).each{|x| c = Address.new(x).balance.to_f; b << [x, c, (100 * c / total).round(2)] }
    @all_addresses = b.sort{|x,y| y[1] <=> x[1] }[0..49]
  end
  
  def show
    @address = Address.new(params[:id])
    @exodus_payments = ExodusTransaction.where(receiving_address: params[:id]).order("tx_date DESC")
    @received_payments = SimpleSend.where(receiving_address: params[:id]).order("tx_date DESC")
    @sent = SimpleSend.where(address: params[:id]).order("tx_date DESC")
    @selling_offers = SellingOffer.where(address: params[:id]).order("tx_date DESC")
  end
end
