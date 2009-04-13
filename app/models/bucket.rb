class Bucket < ActiveRecord::Base
  DEFAULT_PAGE_SIZE = 100

  Temp = Struct.new(:id, :name, :role, :balance)

  belongs_to :account
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  has_many :line_items do
    def page(n, options={})
      size = options.fetch(:size, DEFAULT_PAGE_SIZE)
      records = find(:all, :include => { :event => :line_items },
        :order => "occurred_on DESC",
        :limit => size + 1,
        :offset => n * size)

      [records.length > size, records[0,size]]
    end
  end

  attr_accessible :name, :role

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :account_id, :case_sensitive => false

  def self.default
    Temp.new("r:default", "General", "default", 0)
  end

  def self.aside
    Temp.new("r:aside", "Aside", "aside", 0)
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
end
