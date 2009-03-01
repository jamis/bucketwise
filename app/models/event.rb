class Event < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :user

  has_many :account_entries, :dependent => :destroy
  has_many :bucket_entries, :dependent => :destroy

  alias_method :original_account_entries_assignment, :account_entries=
  alias_method :original_bucket_entries_assignment, :bucket_entries=

  after_create :realize_account_entries, :realize_bucket_entries

  def account_entries=(list)
    if list.any? { |item| item.is_a?(Hash) }
      @account_entries_to_realize = list
    else
      original_account_entries_assignment(list)
    end
  end

  def bucket_entries=(list)
    if list.any? { |item| item.is_a?(Hash) }
      @bucket_entries_to_realize = list
    else
      original_bucket_entries_assignment(list)
    end
  end

  protected

    def realize_account_entries
      if @account_entries_to_realize
        account_entries.destroy_all
        @account_entries_to_realize.each do |entry|
          subscription.accounts.find(entry[:account_id])
          account_entries.create(entry)
        end
        @account_entries_to_realize = nil
      end
    end

    def realize_bucket_entries
      if @bucket_entries_to_realize
        bucket_entries.destroy_all
        @bucket_entries_to_realize.each do |entry|
          account = subscription.accounts.find(entry.delete(:account_id))
          entry[:bucket_id] = account.buckets.create(:name => $1).id if entry[:bucket_id] =~ /^!(.*)/
          bucket_entries.create(entry)
        end
        @bucket_entries_to_realize = nil
      end
    end
end
