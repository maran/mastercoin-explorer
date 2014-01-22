class Api::V1::SellingOffersController < ApplicationController
  respond_to :json

  def index
    @selling_offers = SellingOffer.page(params[:page]).per(10).valid
    respond_with @selling_offers
  end

  def current
    offers = []
    SellingOffer.select("distinct(address)").collect(&:address).each do |address|
      offer = SellingOffer.where(address: address).valid.current
      offers << offer if offer.present?
    end
    respond_with offers
  end
end
