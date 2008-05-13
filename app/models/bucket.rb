class Bucket < ActiveRecord::Base
  belongs_to :account
  has_many :entries
end