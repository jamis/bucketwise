class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"

  belongs_to :subscription
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  attr_accessor :starting_balance
  attr_accessible :name, :role, :starting_balance

  validates_presence_of :name
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

    def recent(n=5)
      find(:all, :limit => n, :order => "updated_at DESC").sort_by(&:name)
    end

    def with_defaults
      buckets = to_a
      buckets << Bucket.default unless buckets.any? { |bucket| bucket.role == "default" }
      buckets << Bucket.aside unless buckets.any? { |bucket| bucket.role == "aside" }
      return buckets
    end
  end

  has_many :line_items
  has_many :account_items

  after_create :create_default_buckets, :set_starting_balance

  def self.template
    new :name => "Account name (e.g. Checking)", :role => "checking | credit-card | nil",
      :starting_balance => { :amount => 0, :occurred_on => Date.today }
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
      LineItem.delete_all :account_id => id
      AccountItem.delete_all :account_id => id
      Bucket.delete_all :account_id => id

      tagged_items = TaggedItem.find_by_sql(<<-SQL.squish)
        SELECT t.* FROM tagged_items t LEFT JOIN events e ON t.event_id = e.id
         WHERE e.subscription_id = #{subscription_id}
           AND NOT EXISTS (
            SELECT * FROM account_items a WHERE a.event_id = e.id)
      SQL

      tagged_items.each { |item| item.destroy }

      connection.delete(<<-SQL.squish)
        DELETE FROM events
         WHERE subscription_id = #{subscription_id}
           AND NOT EXISTS (
            SELECT * FROM account_items a WHERE a.event_id = events.id)
      SQL

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
      buckets.create({:name => DEFAULT_BUCKET_NAME, :role => "default"}, :author => author)
    end

    def set_starting_balance
      if starting_balance && !starting_balance[:amount].to_i.zero?
        subscription.events.create({:occurred_on => starting_balance[:occurred_on],
            :actor => "Starting balance",
            :line_items => [{:account_id => id, :bucket_id => buckets.default.id,
              :amount => starting_balance[:amount], :role => "deposit"}]
          }, :user => author)
        reload # make sure the balance is set correctly
      end
    end
end
