class HomesController < ApplicationController
  def api_docs
  end

  def index
    @transactions = Transaction.limit(10).order("app_position DESC")

    if params[:address]
      redirect_to address_path(params[:address]), notice: "This functionality is now build into the site, you have been redirect"
    end
  end

end
