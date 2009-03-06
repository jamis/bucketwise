module DashboardsHelper
  def balance_cell(account_or_bucket, extra_classes=nil)
    balance = account_or_bucket.balance

    classes = %w(number)
    classes += Array(extra_classes) if extra_classes
    classes << "negative" if balance < 0

    content_tag("td", format_amount(balance), :class => classes.join(" "))
  end

  def format_amount(amount)
    amount = amount.abs

    dollars = amount / 100
    cents   = amount % 100

    "$%s.%02d" % [number_with_delimiter(dollars), cents]
  end
end
