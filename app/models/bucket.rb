class Bucket < ActiveRecord::Base
  RECENT_WINDOW_SIZE = 10

  Temp = Struct.new(:id, :name, :role, :balance)

  belongs_to :account
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  has_many :line_items

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :account_id, :case_sensitive => false

  scope :apply_filter, ->(filter) do
    conditions = []
    parameters = []

    if filter.from?
      conditions << "line_items.occurred_on >= ?"
      parameters << filter.from
    end

    if filter.to?
      conditions << "line_items.occurred_on <= ?"
      parameters << filter.to
    end

    if filter.by_type?
      roles = []

      if filter.expenses?
        roles << 'payment_source'
        roles << 'transfer_from'
        roles << 'credit_options'
      end

      if filter.deposits?
        roles << 'deposit'
        roles << 'transfer_to'
      end

      if filter.reallocations?
        roles << 'primary'
        roles << 'aside'
        roles << 'credit_options'
        roles << 'reallocation_from'
        roles << 'reallocation_to'
      end

      conditions << "line_items.role IN (?)"
      parameters << roles.uniq
    end

    joins("LEFT OUTER JOIN line_items ON line_items.bucket_id = buckets.id")
      .select("buckets.*, SUM(line_items.amount) as computed_balance")
      .where([conditions.join(" AND "), *parameters])
      .group("buckets.id")
  end

  def self.default
    Temp.new("r:default", "General", "default", 0)
  end

  def self.aside
    Temp.new("r:aside", "Aside", "aside", 0)
  end

  def self.template
    new :name => "Bucket name (e.g. Groceries)",
      :role => "aside | default | nil"
  end

  def self.recent(n=RECENT_WINDOW_SIZE)
    limit(n).order("updated_at DESC").sort_by(&:name)
  end

  def balance
    (self[:computed_balance] || self[:balance]).to_i
  end

  def assimilate(bucket)
    if bucket == self
      raise ArgumentError, "cannot assimilate self"
    end

    if bucket.account_id != account_id
      raise ArgumentError, "cannot assimilate bucket from different account"
    end

    old_id = bucket.id

    Bucket.transaction do
      LineItem.where(:bucket_id => old_id).update_all(["bucket_id = ?", id])
      update_attribute :balance, balance + bucket.balance
      bucket.destroy
    end
  end

  def to_xml(options={})
    options[:only] = %w(name role) if new_record?
    JSON.parse(to_json).to_xml(options.merge(root: 'bucket'))
  end
end
