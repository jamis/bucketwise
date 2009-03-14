class Bucket < ActiveRecord::Base
  belongs_to :account
  belongs_to :author, :class_name => "User", :foreign_key => "user_id"

  has_many :line_items

  def balance
    @balance ||= line_items.sum(:amount) || 0
  end
end
