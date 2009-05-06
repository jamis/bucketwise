class Actor < ActiveRecord::Base
  belongs_to :subscription
  has_many :events

  def self.normalize(name)
    name = name.strip
    sort_name = name.upcase

    actor = find_by_sort_name(sort_name)
    if actor
      actor.ping!
      return actor
    end

    create(:sort_name => sort_name, :name => name)
  end
end
