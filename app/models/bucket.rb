class Bucket < ActiveRecord::Base
  belongs_to :account
  has_many :line_items

  def balance
    line_items.sum(:amount) || 0
  end
end
