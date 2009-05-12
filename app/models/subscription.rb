class Subscription < ActiveRecord::Base
  DEFAULT_PAGE_SIZE = 5

  belongs_to :owner, :class_name => "User"

  has_many :accounts
  has_many :tags
  has_many :actors

  has_many :events do
    def recent(n=0, options={})
      size = (options[:size] || DEFAULT_PAGE_SIZE).to_i
      n = n.to_i

      joins = []
      conditions = []
      parameters = []

      if options[:actor]
        joins << "LEFT JOIN actors ON actors.id = events.actor_id"
        conditions << "actors.sort_name = ?"
        parameters << Actor.normalize_name(options[:actor])
      end

      records = find(:all, :joins => joins,
        :conditions => conditions.any? ? [conditions.join(" AND "), *parameters] : nil,
        :include => :account_items,
        :order => "events.created_at DESC",
        :limit => size + 1,
        :offset => n * size)

      [records.length > size, records[0,size]]
    end

    def prepare(attrs={})
      event = build(:role => attrs[:role], :occurred_on => Date.today)

      case event.role
      when :reallocation
        event.actor_name = "Bucket reallocation"
        if attrs[:from]
          bucket = Bucket.find(attrs[:from])
          account = @owner.accounts.find(bucket.account_id)
          event.line_items.build(:role => "primary", :account => account, :bucket => bucket)
          event.line_items.build(:role => "reallocate_from", :account => account, :bucket => account.buckets.default)
        elsif attrs[:to]
          bucket = Bucket.find(attrs[:to])
          account = @owner.accounts.find(bucket.account_id)
          event.line_items.build(:role => "primary", :account => account, :bucket => bucket)
          event.line_items.build(:role => "reallocate_to", :account => account, :bucket => account.buckets.default)
        end
      end

      return event
    end
  end

  has_many :user_subscriptions
  has_many :users, :through => :user_subscriptions

  # removes everything from the subscription, without deleting the subscription
  def clean
    transaction do
      connection.delete "DELETE FROM line_items WHERE event_id IN (SELECT id FROM events WHERE subscription_id = #{id})"
      connection.delete "DELETE FROM account_items WHERE event_id IN (SELECT id FROM events WHERE subscription_id = #{id})"
      connection.delete "DELETE FROM tagged_items WHERE event_id IN (SELECT id FROM events WHERE subscription_id = #{id})"

      connection.delete "DELETE FROM buckets WHERE account_id IN (SELECT id FROM accounts WHERE subscription_id = #{id})"
      connection.delete "DELETE FROM statements WHERE account_id IN (SELECT id FROM accounts WHERE subscription_id = #{id})"

      connection.delete "DELETE FROM actors WHERE subscription_id = #{id}"
      connection.delete "DELETE FROM events WHERE subscription_id = #{id}"
      connection.delete "DELETE FROM accounts WHERE subscription_id = #{id}"
      connection.delete "DELETE FROM tags WHERE subscription_id = #{id}"
    end
  end

  # an optimized destroy to avoid costly dependency cascades
  def destroy
    transaction do
      clean
      connection.delete "DELETE FROM user_subscriptions WHERE subscription_id = #{id}"
      connection.delete "DELETE FROM subscriptions WHERE id = #{id}"
    end
  end
end
