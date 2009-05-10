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
end
