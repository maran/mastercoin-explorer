class Api::V1::TransactionsController < ApplicationController
  respond_to :json

  skip_before_filter :verify_authenticity_token, only: :create

  def index
    @transactions = Transaction.page(params[:page]).per(10)
    render json: @transactions
  end

  def create
    @queued_transaction = TransactionQueue.new(transaction_params)
    Rails.logger.info(params)
    if @queued_transaction.save
      render json: @queued_transaction
    else
      render json: {error: true, errors: @queued_transaction.errors.full_messages}
    end
  end

  def invalid
    @transactions = Transaction.where(invalid_tx: true).page(params[:page]).per(10)
    render json: @transactions
  end

  def exodus
    @transactions = ExodusTransaction.page(params[:page]).per(10)
    render json: @transactions
  end

  def simple_send
    @transactions = SimpleSend.page(params[:page]).per(10)
    render json: @transactions
  end

  def show
    @transaction = Transaction.find_by(tx_id: params[:id])
    render json: @transaction
  end

  def transaction_params
    params[:transaction].permit(:tx_hash, :json_payload)
  end
end
