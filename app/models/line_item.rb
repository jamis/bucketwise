class LineItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :account
  belongs_to :bucket

  after_create :increment_bucket_balance
  before_destroy :decrement_bucket_balance

  protected

    def increment_bucket_balance
      bucket.update_attribute :balance, bucket.balance + amount
    end

    def decrement_bucket_balance
      bucket.update_attribute :balance, bucket.balance - amount
    end
end
