class Account < ActiveRecord::Base
  DEFAULT_BUCKET_NAME = "General"

  belongs_to :subscription

  has_many :buckets do
    def for_role(role)
      role = role.downcase

      bucket = detect { |b| b.role == role }
      if bucket.nil?
        name = role.capitalize
        bucket = create(:name => name, :role => role)
      end

      return bucket
    end

    def default
      detect { |bucket| bucket.role == "default" }
    end
  end

  has_many :line_items
  has_many :account_items

  after_create :create_default_buckets

  def balance
    @balance ||= account_items.sum(:amount) || 0
  end

  protected

    def create_default_buckets
      buckets.create(:name => DEFAULT_BUCKET_NAME, :role => "default")
    end
end
