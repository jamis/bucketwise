class Event < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :user

  has_many :account_entries
  has_many :bucket_entries

  before_validate :prepare_pending_entries

  def payment_source=(list)
    pending_entries += list
  end

  def credit_options=(list)
    pending_entries += list
  end

  def entries=(list)
    pending_entries += list
  end

  protected

    def prepare_pending_entries
      if pending_entries.any?
        entries.destroy_all
        pending_entries.each do |pending|
          if pending[:bucket_id] =~ /^!(.*):(.*?)$/
            account = subscription.accounts.find($2)
            bucket = account.buckets.create(:name => $1).id
          else
          end
        end
        pending_entries.clear
      end
    end

  private

    def pending_entries
      @pending_entries ||= []
    end
end
