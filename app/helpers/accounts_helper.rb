module AccountsHelper
  def account_starting_balance_amount
    if @account && @account.starting_balance
      amount = @account.starting_balance[:amount].to_i
      "%.2f" % (amount / 100.0) unless amount.zero?
    end
  end

  def account_starting_balance_occurred_on
    @account.starting_balance[:occurred_on].to_date rescue Date.today
  end
end
