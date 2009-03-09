module DashboardsHelper
  def balance_cell(account_or_bucket, extra_classes=nil)
    balance = real_balance = account_or_bucket.balance
    if account_or_bucket.respond_to?(:available_balance)
      balance = account_or_bucket.available_balance
    end

    classes = %w(number)
    classes += Array(extra_classes) if extra_classes
    classes << "negative" if balance < 0

    content = format_amount(balance)
    if real_balance != balance
      content = "<span class='real_balance'>(" << format_amount(real_balance) << ")</span> #{content}"
    end

    content_tag("td", content, :class => classes.join(" "), :style => "white-space: nowrap")
  end

  def format_amount(amount)
    amount = amount.abs

    dollars = amount / 100
    cents   = amount % 100

    "$%s.%02d" % [number_with_delimiter(dollars), cents]
  end
end
