class Account < ActiveRecord::Base
  belongs_to :subscription
  has_many :buckets
  has_many :entries, :class_name => "AccountEntry"
end