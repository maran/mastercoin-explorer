class SimpleSendsController < ApplicationController
  def new
    redirect_to root_path, notice: "Simple send is disabled for now, please use the wallet software or check back later"
    @simple_send = SimpleSend.new
  end

  def create
    @simple_send= SimpleSend.new(simple_send_params)
    if @simple_send.valid? && @simple_send.has_funds?
      @simple_send.send_simple_send
    else
      render :new
    end
  end

  def simple_send_params
    params[:simple_send].permit(:currency_id, :public_key, :amount, :receiving_address)
  end
end
