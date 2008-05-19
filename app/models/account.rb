class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"

  belongs_to :subscription
  has_many :buckets
  has_many :entries, :class_name => "AccountEntry"

  after_create :create_default_bucket

  protected

    def create_default_bucket
      buckets.create(:name => DEFAULT_BUCKET_NAME)
    end
end