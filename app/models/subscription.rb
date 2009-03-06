class Subscription < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :accounts

  has_many :events do
    def recent(n=5)
      find(:all, :order => "created_at DESC", :limit => n, :include => :account_items)
    end
  end

  has_many :user_subscriptions
  has_many :users, :through => :user_subscriptions
end
