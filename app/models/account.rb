class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"
  ASIDE_BUCKET_NAME = "Aside"

  belongs_to :subscription

  has_many :buckets do
    def aside
      detect { |bucket| bucket.role == "aside" }
    end
  end

  has_many :entries, :class_name => "AccountEntry"

  after_create :create_default_buckets

  protected

    def create_default_buckets
      buckets.create(:name => DEFAULT_BUCKET_NAME, :role => "default")
      buckets.create(:name => ASIDE_BUCKET_NAME, :role => "aside")
    end
end
