module EventsHelper
  def accounts_and_buckets_as_javascript
    subscription.accounts.inject("") do |memo, account|
      memo << "," unless memo.blank?
      memo << account.id.to_s << ":{id:#{account.id},name:#{account.name.to_json},role:#{account.role.to_json},buckets:["
      memo << account.buckets.inject("") do |m, bucket|
        m << "," unless m.blank?
        m << "{id:#{bucket.id},name:#{bucket.name.to_json}}"
      end
      memo << "]}"
    end
  end

  def select_account(section)
    select_tag "event[entry][][account_id]", 
      options_for_select([["", ""]] + subscription.accounts.map { |acct| [acct.name, acct.id] }),
      :id => "account_for_#{section}",
      :onchange => "Events.handleAccountChange(this, '#{section}')"
  end

  def select_bucket(section)
    select_tag "event[entry][][bucket_id]", "<option>-- Select an account --</option>",
      :id => "bucket_for_#{section}", :disabled => true,
      :onchange => "Events.handleBucketChange(this, '#{section}')"
  end
end