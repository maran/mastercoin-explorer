class PurchaseOffersController < ApplicationController
  def new
    @purchase_offer = PurchaseOffer.new
    @purchase_offer.receiving_address = params[:address] if params[:address]
    @purchase_offer.amount = params[:amount] if params[:amount]
    @purchase_offer.currency_id = params[:currency_id] if params[:currency_id]
    @purchase_offer.forced_fee = params[:forced_fee] if params[:forced_fee]
  end

  def create
    @purchase_offer= PurchaseOffer.new(offer_params)
    if @purchase_offer.valid? && @purchase_offer.has_funds?
      @purchase_offer.create_purchase_offer
    else
      render :new
    end
  end

  def offer_params
    params[:purchase_offer].permit(:currency_id, :public_key, :amount, :receiving_address, :forced_fee)
  end
end
