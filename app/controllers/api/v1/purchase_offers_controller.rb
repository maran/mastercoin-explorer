class Api::V1::PurchaseOffersController < ApplicationController
  respond_to :json

  def index
    @purchase_offers = PurchaseOffer.page(params[:page]).per(10)
    respond_with @purchase_offers
  end
end
