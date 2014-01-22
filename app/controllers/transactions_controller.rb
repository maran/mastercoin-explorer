class TransactionsController < ApplicationController
  def show
    @transaction = Transaction.where(tx_id: params[:id]).first
    if @transaction.nil? || @transaction.type.nil?
      redirect_to root_path, notice: "Could not find transaction with transaction id #{params[:id]}"
      return
    end

    if ["SimpleSend", "ExodusPayment"].include?(@transaction.type)
      render :show
    elsif "SellingOffer" == @transaction.type
      render :selling_offer
    elsif "PurchaseOffer" == @transaction.type
      render :purchase_offer
    end
  end

  def index
    @transactions = Transaction.where(invalid_tx: true).order("tx_date DESC, position DESC")
  end
end
