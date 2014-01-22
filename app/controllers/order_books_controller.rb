class OrderBooksController < ApplicationController
  def index
    @offers = []
    SellingOffer.select("distinct(address)").collect(&:address).each do |address|
      offer = SellingOffer.where(address: address).valid.current
      @offers << offer if offer.present?
    end
  end
end
