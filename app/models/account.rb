class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"

  # When should the levels of credit cards be reached (in %)
  DEFAULT_LIMIT_VALUES = {
    :critical => 100,
    :high => 80,
    :medium => 30,
    :low => 0
  }

  belongs_to :subscription
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  attr_accessor :starting_balance
  # attr_accessible :name, :role, :limit, :starting_balance

  validates_presence_of :name
  validates_presence_of :limit, :if => :credit_card?
  validates_uniqueness_of :name, :scope => :subscription_id, :case_sensitive => false

  has_many :buckets do
    def for_role(role, user)
      role = role.downcase
      find_by_role(role) || create({:name => role.capitalize, :role => role}, :author => user)
    end

    def sorted
      sort_by(&:name)
    end

    def default
      detect { |bucket| bucket.role == "default" }
    end

    def with_defaults
      buckets = to_a.dup
      buckets << Bucket.default unless buckets.any? { |bucket| bucket.role == "default" }
      buckets << Bucket.aside unless buckets.any? { |bucket| bucket.role == "aside" }
      return buckets
    end
  end

  has_many :line_items
  has_many :statements

  has_many :account_items, :extend => CategorizedItems

  after_create :create_default_buckets, :set_starting_balance

  def self.template
    new :name => "Account name (e.g. Checking)", :role => "checking | credit-card | nil",
      :starting_balance => { :amount => 0, :occurred_on => Date.today }
  end

  def credit_card?
    role == 'credit-card'
  end

  def checking?
    role == 'checking'
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

  def destroy
    transaction do
      cleanup_account_items
      cleanup_line_items
      cleanup_buckets
      cleanup_tagged_items
      cleanup_events

      Account.delete(id)
    end
  end

  def to_xml(options={})
    if new_record?
      options[:only] = %w(name role)
      options[:procs] = Proc.new do |opts|
        starting_balance.to_xml(opts.merge(:root => "starting-balance"))
      end
    end

    super(options)
  end

  protected

    def create_default_buckets
      buckets.where(author: author).create({:name => DEFAULT_BUCKET_NAME, :role => "default"})
    end

    def set_starting_balance
      if starting_balance && !starting_balance[:amount].to_i.zero?
        amount = starting_balance[:amount].to_i
        role = amount > 0 ? "deposit" : "payment_source"
        subscription.events.where(user: author).create!({:occurred_on => starting_balance[:occurred_on],
            :actor_name => "Starting balance",
            :line_items => [{:account_id => id, :bucket_id => buckets.default.id,
              :amount => amount, :role => role}]
          })
        reload # make sure the balance is set correctly
      end
    end

  private

    def cleanup_line_items
      LineItem.where(account_id: id).delete_all
    end

    def cleanup_account_items
      items = account_items.includes(:event => [:line_items, :account_items])
                # .find(:all, :include => { :event => [:line_items, :account_items] })

      items.each do |item|
        event = item.event
        next unless event.account_items.length > 1

        case event.role
        when :transfer then
          # if half of a transfer is being deleted, convert the other half to either a deposit
          # or an expense, depending on whether the half being deleted is the negative or
          # positive half.
          event.line_items.update_all(:role => (item.amount < 0 ? 'deposit' : 'payment_source'))

        when :expense then
          # if the credit_options account is being deleted, we don't need to do anything,
          # but if the payment_source account is being deleted, then we need to convert the
          # credit_options items to a bucket reallocation.
          if event.account_for(:payment_source) == self
            event.line_items.where(role: 'aside').update_all({:role => 'primary'})
            event.line_items.where(role: 'credit_options').update_all({:role => 'reallocate_to'})
          end
        end
      end

      AccountItem.where(account_id: id).delete_all
    end

    def cleanup_buckets
      Bucket.where(account_id: id).delete_all
    end

    def cleanup_tagged_items
      tagged_items = TaggedItem.find_by_sql(<<-SQL.squish)
        SELECT t.* FROM tagged_items t LEFT JOIN events e ON t.event_id = e.id
         WHERE e.subscription_id = #{subscription_id}
           AND NOT EXISTS (
            SELECT * FROM account_items a WHERE a.event_id = e.id)
      SQL

      tagged_items.each { |item| item.destroy }
    end

    def cleanup_events
      ActiveRecord::Base.connection.delete(<<-SQL.squish)
        DELETE FROM events
         WHERE subscription_id = #{subscription_id}
           AND NOT EXISTS (
            SELECT * FROM account_items a WHERE a.event_id = events.id)
      SQL
    end
end
