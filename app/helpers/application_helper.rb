module ApplicationHelper
  def valid_label(payment)
    if payment.invalid_tx?
      "<span class='label label-danger'>Invalid</span>"
    else
      "<span class='label label-success'>Valid</span>"
    end
  end
end
