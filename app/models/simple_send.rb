class SimpleSend < Transaction
  # TODO: Add a function to check if the same block has multiple txes and use position to determine the winner
  # TODO: Create specs
  # 1. Check if funds were present at the time; ignore if not but make sure a next payment should work
  # 2. Check if multiple payments in the same block were made that would throw balance in the minus
  after_create :check_transaction_validity
  
  def refresh!
    self.block_height = raw_tx.get_block.depth
    self.tx_date = Time.at(raw_tx.get_block.time)
    self.invalid_tx = false
    self.save
    self.check_transaction_validity
  end

  def raw_tx
    Mastercoin.storage.get_tx(self.tx_id)
  end

  # Weekly charts
  def self.collect_weekly_chart_data
    amount_transferred = 7.times.collect do |x|
      
      start_date = Date.today
      end_date = start_date-x.day
      amount = SimpleSend.where("tx_date BETWEEN ? AND ?", end_date, end_date + 1.day).sum(:amount)
      x += 1
      amount.to_f
    end
    { name: 'Simple Send', data: amount_transferred.reverse }
  end

  def self.collect_weekly_date
    date_transferred = 7.times.collect do |x|
      
      start_date = Date.today
      end_date = start_date-x.day
      date = end_date
      x += 1
      date.strftime("%d-%m-%Y")
    end
    date_transferred.reverse
  end

  # Yearly charts   
  def self.collect_yearly_chart_data
    amount_transferred = 12.times.collect do |x|
     
      x += 1
      start_date = Date.parse("2013-#{x.to_s.rjust(2,'0')}-01")
      end_date = start_date.end_of_month
      amount = SimpleSend.where("tx_date BETWEEN ? AND ?", start_date, end_date).sum(:amount)
      amount.to_f
    end
    { name: 'Simple Send', data: amount_transferred }
  end

  def self.collect_yearly_date
    date_transferred = 12.times.collect do |x|

      start_date = Date.today.beginning_of_year
      date = start_date+x.month
      x += 1
      date.strftime("%B")
    end
    date_transferred
  end

  # Monthly charts
  def self.collect_monthly_chart_data
      amount_transferred = (Date.today.beginning_of_month..Date.today.end_of_month).count.times.collect do |x|
      
      start_date = Date.today
      end_date = start_date-x.day
      amount = SimpleSend.where("tx_date BETWEEN ? AND ?", end_date, end_date + 1.day).sum(:amount)
      x += 1
      amount.to_f
    end
    { name: 'Simple Send', data: amount_transferred.reverse }
  end

  def self.collect_monthly_date
     date_transferred = (Date.today.beginning_of_month..Date.today.end_of_month).count.times.collect do |x|

      start_date = Date.today
      end_date = start_date-x.day
      date = end_date
      x += 1
      date.strftime("%d-%m-%Y")
    end
    date_transferred.reverse
  end

end
