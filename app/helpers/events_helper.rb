module EventsHelper
  def accounts_and_buckets_as_javascript
    subscription.accounts.inject("") do |memo, account|
      memo << "," unless memo.blank?
      memo << account.id.to_s << ":{id:#{account.id},name:#{account.name.to_json},role:#{account.role.to_json},buckets:["
      memo << account.buckets.sort_by(&:name).inject("") do |m, bucket|
        m << "," unless m.blank?
        m << "{id:#{bucket.id},name:#{bucket.name.to_json},role:#{bucket.role.to_json}}"
      end
      memo << "]}"
    end
  end

  def tags_as_javascript
    subscription.tags.map(&:name).sort.to_json
  end

  def links_to_accounts_for_event(event)
    links = event.account_items.map do |item|
      link_to(h(item.account.name), item.account)
    end

    links.join(", ")
  end

  def form_sections
    %w(payment_source
       credit_options
       deposit
       transfer_from
       transfer_to)
  end

  def select_account(section, accounts, selection)
    select_tag "event[#{section}][account_id]", 
      options_for_select(
        (selection ? [] : [["", ""]]) +
          accounts.map { |acct| [acct.name, acct.id] },
        selection),
      :id => "account_for_#{section}",
      :onchange => "Events.handleAccountChange(this, '#{section}')"
  end

  def select_bucket(section, options={})
    if options[:line_item]
      select_options = options_for_select(
        options[:line_item].account.buckets.sorted.map { |bucket| [bucket.name, bucket.id] },
        options[:line_item].bucket_id)
      disabled = false
    else
      select_options = "<option>-- Select an account --</option>"
      disabled = true
    end

    classes = ["bucket_for_#{section}", options.fetch(:splittable, true) ? "splittable" : nil]

    select_tag "event[#{section}][bucket_id]", select_options,
      :class => classes.compact.join(" "),
      :disabled => disabled,
      :onchange => "Events.handleBucketChange(this, '#{section}')"
  end

  def event_for_form
    @event || Event.new(:occurred_on => Date.today)
  end

  def event_form_action
    if @event
      update_event_path(@event)
    else
      subscription_events_path(subscription)
    end
  end

  def event_amount_value
    if @event
      if @event.role == :transfer
        balance = @event.account_items.map { |a| a.amount.abs }.max
      else
        balance = @event.balance.abs
      end

      "%.2f" % (balance / 100.0)
    else
      ""
    end
  end

  def line_item_amount_value(item)
    if item
      "%.2f" % (item.amount.abs / 100.0)
    else
      ""
    end
  end

  def tagged_item_name_value(item)
    if item
      item.tag.name
    else
      ""
    end
  end

  def tagged_item_amount_value(item)
    if item
      "%.2f" % (item.amount.abs / 100.0)
    else
      ""
    end
  end

  def tag_list_for_event
    if @event
      @event.tagged_items.whole.map(&:tag).map(&:name).sort.join(", ")
    else
      ""
    end
  end

  def section_wants_check_options?(section)
    case section
    when :payment_source, :transfer_from, :deposit
      true
    else
      false
    end
  end

  def event_wants_section?(section)
    return true unless @event

    case section.to_sym
    when :payment_source, :credit_options then
      return @event.role == :expense
    when :deposit then
      return @event.role == :deposit
    when :transfer_from, :transfer_to then
      return @event.role == :transfer
    end

    return false
  end

  def event_has_tags?
    @event && @event.tagged_items.any?
  end

  def event_has_partial_tags?
    @event && @event.tagged_items.partial.any?
  end

  def section_visible_for_event?(section)
    return true unless @event

    if @event.role == :expense && section == :credit_options
      return @event.line_items.for_role(:credit_options).any?
    end

    return true
  end

  def section_has_single_bucket?(section)
    return false if @event && @event.line_items.for_role(section).length > 1
    return true
  end

  def multi_bucket_visibility_for(section)
    return nil if @event && @event.line_items.for_role(section).length > 1
    return "display: none;"
  end

  def for_each_line_item_in(section)
    (@event && @event.line_items.for_role(section) || []).each do |item|
      yield item
    end
  end

  def for_each_partial_tagged_item
    (@event && @event.tagged_items.partial || []).each do |item|
      yield item
    end
  end

  def line_item_for_section(section)
    @event && @event.line_items.for_role(section).first
  end

  def bucket_action_phrase_for(section)
    case section.to_sym
    when :payment_source
      "was drawn from"
    when :credit_options
      "will be repaid from"
    when :deposit
      "was deposited to"
    when :transfer_from
      "was transferred from"
    when :transfer_to
      "was transferred to"
    else raise ArgumentError, "unsupported form section: #{section.inspect}"
    end
  end

  FORM_SECTIONS = {
    :deposit => {
      :title                => "Deposit Information",
      :account_prompt       => "<strong>Which account</strong> was this deposited to?",
      :single_bucket_prompt => "<strong>Which bucket</strong> was this deposited to?",
      :multi_bucket_prompt  => "This deposit was to multiple buckets."
    },
    :credit_options => {
      :title                => "Repayment Options",
      :account_prompt       => "<strong>Which account</strong> will be used to " +
                               "<strong>repay this credit</strong>?",
      :single_bucket_prompt => "<strong>Which bucket</strong> will be used to " +
                               "<strong>repay this credit</strong>?",
      :multi_bucket_prompt  => "Multiple buckets will be used to repay this credit.",
    },
    :payment_source => {
      :title                => "Payment Source",
      :account_prompt       => "<strong>Which account</strong> was this drawn from?",
      :single_bucket_prompt => "<strong>Which bucket</strong> was this drawn from?",
      :multi_bucket_prompt  => "This expense drew from multiple buckets."
    },
    :transfer_from => {
      :title                => "Transfer Source",
      :account_prompt       => "<strong>Which account</strong> were funds transferred " +
                               "<strong>from</strong>?",
      :single_bucket_prompt => "<strong>Which bucket</strong> were funds transferred from?",
      :multi_bucket_prompt  => "This transfer pulled from multiple buckets."
    },
    :transfer_to => {
      :title                => "Transfer Destination",
      :account_prompt       => "<strong>Which account</strong> were funds transferred " +
                               "<strong>to</strong>?",
      :single_bucket_prompt => "<strong>Which bucket</strong> were funds transferred to?",
      :multi_bucket_prompt  => "This transfer targetted multiple buckets."
    }
  }

  def render_event_form_section(form, section)
    section = section.to_sym

    accounts = subscription.accounts
    accounts = accounts.select { |a| a.role == "checking" } if section == :credit_options

    values = { :section          => section,
               :form             => form,
               :accounts         => accounts,
               :selected_account => form.object && form.object.account_for(section) }

    render :partial => "events/form_section",
           :locals => FORM_SECTIONS[section].merge(values)
  end

  def tag_links_for(event)
    event.tags.sort_by(&:name).map { |tag| link_to(h(tag.name), tag_path(tag)) }.join(", ")
  end
end
