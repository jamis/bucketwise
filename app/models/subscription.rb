class Subscription < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :accounts
  has_many :events

  has_many :user_subscriptions
  has_many :users, :through => :user_subscriptions
end