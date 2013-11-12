class HomesController < ApplicationController
  def api_docs
  end

  def index
    @transactions = Transaction.limit(10).order("app_position DESC")

    if params[:address]
      require 'mastercoin'
      @result = Mastercoin::BuyingAddress.from_address(params[:address]) 
    end
  end

end
