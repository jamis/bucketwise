module SubscriptionsHelper
  def blank_slate?
    subscription.accounts.empty?
  end

  def balance_cell(container, options={})
    balance = real_balance = container.balance
    if container.respond_to?(:available_balance)
      balance = container.available_balance
    end

    classes = %w(number)
    classes += Array(options[:classes]) if options[:classes]
    classes << "negative" if balance < 0
    classes << "current_balance"

    if container.is_a?(Account) && container.credit_card? && !container.limit.blank?
      percentage_used = container.limit.abs.to_i == 0 ? 100 :
        ((container.balance.abs.to_f / container.limit.abs.to_f) * 100).to_i
      classes << if percentage_used >= Account::DEFAULT_LIMIT_VALUES[:critical]
                  "critical"
                elsif percentage_used >= Account::DEFAULT_LIMIT_VALUES[:high]
                  "high"
                elsif percentage_used >= Account::DEFAULT_LIMIT_VALUES[:medium]
                  "medium"
                else
                  "low"
                end
    end

    content = format_amount(balance)
    if real_balance != balance
      content = content_tag(:span, "(#{format_amount(real_balance)})",
                            class: :real_balance)
    end

    content_tag(options.fetch(:tag, "td"), content, :class => classes.join(" "), :id => options[:id])
  end

  def format_amount(amount)
    amount = amount.abs

    dollars = amount / 100
    cents   = amount % 100

    "$%s.%02d" % [number_with_delimiter(dollars), cents]
  end
end
