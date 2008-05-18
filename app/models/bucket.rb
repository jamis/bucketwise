class Bucket < ActiveRecord::Base
  belongs_to :account
  has_many :entries, :class_name => "BucketEntry"
end