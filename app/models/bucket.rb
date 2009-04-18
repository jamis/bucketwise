class Bucket < ActiveRecord::Base
  Temp = Struct.new(:id, :name, :role, :balance)

  belongs_to :account
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  has_many :line_items

  attr_accessible :name, :role

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :account_id, :case_sensitive => false

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

  def assimilate(bucket)
    if bucket == self
      raise ArgumentError, "cannot assimilate self"
    end

    if bucket.account_id != account_id
      raise ArgumentError, "cannot assimilate bucket from different account"
    end

    old_id = bucket.id

    Bucket.transaction do
      LineItem.update_all(["bucket_id = ?", id], :bucket_id => old_id)
      update_attribute :balance, balance + bucket.balance
      bucket.destroy
    end
  end

  def to_xml(options={})
    options[:only] = %w(name role) if new_record?
    super(options)
  end
end
