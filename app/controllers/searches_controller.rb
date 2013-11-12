class SearchesController < ApplicationController
  def index
    search_for = params[:searching].strip

    return redirect_to transaction_path(search_for) if Transaction.find_by(tx_id: search_for)
    return redirect_to address_path(search_for) if Transaction.where("receiving_address = ? OR address = ?", search_for, search_for).any?
    
    redirect_to root_path, notice: "Sorry could not find what you were searching for."
  end
end
