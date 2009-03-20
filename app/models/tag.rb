class Tag < ActiveRecord::Base
  belongs_to :subscription
  has_many :tagged_items
end
