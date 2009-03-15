class LineItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :account
  belongs_to :bucket

  after_create :ping_bucket

  protected

    def ping_bucket
      bucket.ping!
    end
end
