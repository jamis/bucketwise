module EventsHelper
  def select_account(section)
    select_tag "event[entry][][account_id]", 
      options_for_select([["", ""]] + subscription.accounts.map { |acct| [acct.name, acct.id] }),
      :id => "account_for_#{section}",
      :onchange => "$('#{section}.multiple_buckets').hide(); $('#{section}.single_bucket').show(); Events.updateBucketsFor(this, '#{section}')"
  end

  def select_bucket(section)
    select_tag "event[entry][][bucket_id]", "<option>-- Select an account --</option>",
      :id => "bucket_for_#{section}", :disabled => true,
      :onchange => "Events.handleBucketChange(this, '#{section}')"
  end
end