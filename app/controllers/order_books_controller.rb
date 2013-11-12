class OrderBooksController < ApplicationController
  def index
    @offers = SellingOffer.order("price_per_coin ASC").where(current: true).limit(10)
  end
end
