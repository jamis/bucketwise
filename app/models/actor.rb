class Actor < ActiveRecord::Base
  belongs_to :subscription
  has_many :events

  validates_presence_of :name, :sort_name
  # attr_accessible :name, :sort_name

  def self.normalize_name(name)
    name.strip.upcase
  end

  def self.normalize(name)
    name = name.strip
    sort_name = normalize_name(name)

    actor = find_by_sort_name(sort_name)
    if actor
      actor.ping!
      return actor
    end

    create(:sort_name => sort_name, :name => name)
  end
end
