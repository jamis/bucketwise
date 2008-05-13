class Event < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :user

  has_many :entries
end