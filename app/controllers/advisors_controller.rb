class AdvisorsController < ApplicationController
  def sell
    @advisor = Advisor.new(params[:advisor])
    if @advisor.valid? && @advisor.send_selling_offer
      render :create
    else
      render :new
    end
  end

  def create
    @advisor = Advisor.new(params[:advisor])
    if @advisor.valid? && @advisor.send_simple_send
      render :create
    else
      render :new
    end
  end

  def new
    @advisor = Advisor.new
    redirect_to root_path, notice: "Advisor is disabled to not promote parasitic transactions"
  end
end
