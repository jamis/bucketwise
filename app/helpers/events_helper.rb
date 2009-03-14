module EventsHelper
  def accounts_and_buckets_as_javascript
    subscription.accounts.inject("") do |memo, account|
      memo << "," unless memo.blank?
      memo << account.id.to_s << ":{id:#{account.id},name:#{account.name.to_json},role:#{account.role.to_json},buckets:["
      memo << account.buckets.inject("") do |m, bucket|
        m << "," unless m.blank?
        m << "{id:#{bucket.id},name:#{bucket.name.to_json},role:#{bucket.role.to_json}}"
      end
      memo << "]}"
    end
  end

  def links_to_accounts_for_event(event)
    links = event.account_items.map do |item|
      link_to(h(item.account.name), item.account)
    end

    links.join(", ")
  end

  def select_account(section)
    accounts = subscription.accounts.to_a
    accounts = accounts.select { |a| yield a } if block_given?

    select_tag "event[#{section}][][account_id]", 
      options_for_select([["", ""]] + accounts.map { |acct| [acct.name, acct.id] }),
      :id => "account_for_#{section}",
      :onchange => "Events.handleAccountChange(this, '#{section}')"
  end

  def select_bucket(section, options={})
    select_tag "event[#{section}][][bucket_id]", "<option>-- Select an account --</option>",
      :class => ["bucket_for_#{section}", options.fetch(:splittable, true) ? "splittable" : nil].compact.join(" "),
      :disabled => true,
      :onchange => "Events.handleBucketChange(this, '#{section}')"
  end

  def event_for_form
    @event || Event.new(:occurred_on => Date.today)
  end
end
