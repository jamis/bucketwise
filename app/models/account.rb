class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"

  belongs_to :subscription
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  attr_accessor :starting_balance

  has_many :buckets do
    def for_role(role, user)
      find_or_create_by_role(:role => role.downcase, :name => role.downcase.capitalize,
        :author => user)
    end

    def default
      detect { |bucket| bucket.role == "default" }
    end
  end

  has_many :line_items
  has_many :account_items

  after_create :create_default_buckets, :set_starting_balance

  def balance
    @balance ||= account_items.sum(:amount) || 0
  end

  def available_balance
    @available_balance ||= balance - unavailable_balance
  end

  def unavailable_balance
    @unavailable_balance ||= begin
      aside = buckets.detect { |bucket| bucket.role == 'aside' }
      aside && aside.balance > 0 ? aside.balance : 0
    end
  end

  protected

    def create_default_buckets
      buckets.create(:name => DEFAULT_BUCKET_NAME, :role => "default", :author => author)
    end

    def set_starting_balance
      if starting_balance && !starting_balance[:amount].to_i.zero?
        subscription.events.create(:occurred_on => starting_balance[:occurred_on],
          :actor => "Starting balance", :user_id => user_id,
          :line_items => [{:account_id => id, :bucket_id => buckets.default.id,
            :amount => starting_balance[:amount], :role => "deposit"}])
      end
    end
end
