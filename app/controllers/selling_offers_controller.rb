class SellingOffersController < ApplicationController
  def new
    @selling_offer = SellingOffer.new
  end

  def create
    @selling_offer = SellingOffer.new(offer_params)
    if @selling_offer.valid? && @selling_offer.has_funds?
      @selling_offer.create_selling_offer
    else
      render :new
    end
  end

  def offer_params
    params[:selling_offer].permit(:currency_id, :public_key, :amount, :amount_desired, :time_limit, :required_fee, :currency_id)
  end
end
