class Account < ActiveRecord::Base
  belongs_to :subscription
  has_many :buckets
  has_many :entries
end