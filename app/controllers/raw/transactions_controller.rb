class Raw::TransactionsController < ApplicationController
  def show
    begin 
      @transaction = Mastercoin::Transaction.new(params[:id])
    rescue Mastercoin::TransactionNotFoundException
      redirect_to root_path, notice: "Sorry, it seems my blockchain is still catching up or the transaction does not exist."
    rescue Mastercoin::Transaction::NoMastercoinTransactionException
      redirect_to root_path, notice: "Sorry, I can't parse this transaction as a Mastercoin transaction."
    end
  end

  def index
    redirect_to raw_transaction_path(params[:id])
  end
end
