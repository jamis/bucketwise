class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"
  ASIDE_BUCKET_NAME = "Aside"

  belongs_to :subscription

  has_many :buckets do
    def aside
      detect { |bucket| bucket.role == "aside" }
    end

    def default
      detect { |bucket| bucket.role == "default" }
    end
  end

  has_many :line_items
  has_many :account_items

  after_create :create_default_buckets

  def balance
    account_items.sum(:amount) || 0
  end

  protected

    def create_default_buckets
      buckets.create(:name => DEFAULT_BUCKET_NAME, :role => "default")
      buckets.create(:name => ASIDE_BUCKET_NAME, :role => "aside")
    end
end
