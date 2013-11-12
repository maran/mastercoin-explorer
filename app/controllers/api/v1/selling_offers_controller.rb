class Api::V1::SellingOffersController < ApplicationController
  respond_to :json

  def index
    @selling_offers = SellingOffer.page(params[:page]).per(10)
    respond_with @selling_offers
  end

  def current
    @selling_offers = SellingOffer.page(params[:page]).per(15).where(current: true)
    respond_with @selling_offers
  end
end
