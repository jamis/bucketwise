class Subscription < ActiveRecord::Base
  belongs_to :owner, :class_name => "User"

  has_many :accounts
  has_many :events

  has_many :subscribed_users
  has_many :users, :through => :subscribed_users
end