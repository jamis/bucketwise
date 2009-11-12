class Populator
  def self.for(subscription)
    populator = new(subscription)
    yield populator
    populator.commit!
  end

  attr_reader :subscription

  def initialize(subscription)
    @subscription = subscription
    @accounts = []
    @posts = []
  end

  def account(name, role, starting_balance, balance_date, limit=nil)
    raise "you have to specify a limit for credit-card accounts" if role == "credit-card" && limit.nil?
    @accounts << { :name => name, :role => role, :limit => limit,
        :starting_balance => { :amount => starting_balance, :occurred_on => balance_date }}
  end

  def post(occurred_on, actor_name, default_amount=nil)
    returning Post.new(occurred_on, actor_name, default_amount) do |post|
      @posts << post
    end
  end

  def commit!
    Account.transaction do
      @accounts.each do |account|
        subscription.accounts.create!(account, :author => subscription.users.rand)
      end

      acct_cache = Hash.new { |h,k| h[k] = subscription.accounts.find_by_name(k) or raise IndexError, "key not found: #{k}" }

      @posts.each do |post|
        post.line_items.each do |item|
          if acct_name = item.delete(:account)
            acct = acct_cache[acct_name]
            item[:account_id] = acct.id
          end

          if bucket_name = item.delete(:bucket)
            if bucket_name =~ /^[rn]:/
              item[:bucket_id] = bucket_name
            else
              item[:bucket_id] = "n:#{bucket_name}"
            end
          end
        end

        event_data = { :occurred_on => post.occurred_on, :actor_name => post.actor_name,
          :check_number => post.check_number, :memo => post.memo,
          :line_items => post.line_items, :tagged_items => post.tagged_items }

        subscription.events.create!(event_data, :user => subscription.users.rand)
      end
    end
  end

  class Post
    attr_reader :occurred_on, :actor_name, :check_number
    attr_reader :default_amount
    attr_reader :line_items, :tagged_items

    def initialize(occurred_on, actor_name, default_amount)
      @occurred_on = occurred_on
      @actor_name = actor_name
      @default_amount = default_amount
      @line_items = []
      @tagged_items = []
      @check_number = @memo = nil
    end

    def check(number)
      @check_number = number
      self
    end

    def memo(text=nil)
      if text
        @memo = text
        self
      else
        @memo
      end
    end

    def copy(post)
      @memo = post.memo && post.memo.dup
      @default_amount = post.default_amount
      @line_items = Marshal.load(Marshal.dump(post.line_items))
      @tagged_items = Marshal.load(Marshal.dump(post.tagged_items))
      self
    end

    def source(account, bucket)
      make_line_items(account, "payment_source", bucket, true)
      self
    end

    def repay(account, bucket)
      make_line_items(account, "credit_options", bucket, true)
      line_items << { :role => "aside", :account => account, :bucket_id => "r:aside", :amount => default_amount }
      self
    end

    def deposit(account, bucket)
      make_line_items(account, "deposit", bucket, false)
      self
    end

    def from(account, bucket)
      make_line_items(account, "transfer_from", bucket, true)
      self
    end

    def to(account, bucket)
      make_line_items(account, "transfer_to", bucket, false)
      self
    end

    def reallocate(account, direction, primary, buckets)
      balance = make_line_items(account, "reallocate_#{direction}", buckets, direction == :to)
      line_items << { :role => "primary", :account => account, :bucket => primary,
        :amount => (direction == :from ? -1 : 1) * balance }
      self
    end

    def tag(*tags)
      partials = tags.last.is_a?(Hash) ? tags.pop : {}

      tags.each do |name|
        tagged_items << { :tag_id => "n:#{name}", :amount => default_amount }
      end

      partials.each do |name, amount|
        tagged_items << { :tag_id => "n:#{name}", :amount => amount }
      end

      self
    end

    private

      def each_item(items)
        sum = 0

        Array(items).each do |item|
          bucket, amount = Array(item)
          amount ||= default_amount
          sum += amount
          yield bucket, amount
        end

        @default_amount ||= sum
        return sum
      end

      def make_line_items(account, role, items, expense)
        each_item(items) do |name, amount|
          line_items << { :role => role, :account => account, :bucket => name,
            :amount => (expense ? -1 : 1) * amount }
        end
      end
  end
end

