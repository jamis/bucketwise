module DashboardsHelper
  def balance_cell(account_or_bucket, options={})
    balance = real_balance = account_or_bucket.balance
    if account_or_bucket.respond_to?(:available_balance)
      balance = account_or_bucket.available_balance
    end

    classes = %w(number)
    classes += Array(options[:classes]) if options[:classes]
    classes << "negative" if balance < 0

    content = format_amount(balance)
    if real_balance != balance
      content = "<span class='real_balance'>(" << format_amount(real_balance) << ")</span> #{content}"
    end

    content_tag(options.fetch(:tag, "td"), content, :class => classes.join(" "))
  end

  def format_amount(amount)
    amount = amount.abs

    dollars = amount / 100
    cents   = amount % 100

    "$%s.%02d" % [number_with_delimiter(dollars), cents]
  end
end
