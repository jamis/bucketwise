class BucketEntry < ActiveRecord::Base
  belongs_to :event
  belongs_to :bucket
end