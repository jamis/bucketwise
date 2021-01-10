class Tag < ActiveRecord::Base
  belongs_to :subscription

  has_many :tagged_items, :dependent => :delete_all

  # attr_accessible :name

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :subscription_id, :case_sensitive => false

  def self.template
    new :name => "name of tag"
  end

  def assimilate(tag)
    raise ActiveRecord::RecordNotSaved, "cannot assimilate self" if tag == self

    transaction do
      connection.update <<-SQL.squish
        UPDATE tagged_items
           SET tag_id = #{id}
         WHERE tag_id = #{tag.id}
      SQL
      tag.tagged_items.reset

      update_attribute :balance, balance + tag.balance
      tag.destroy
    end
  end

  def to_xml(options={})
    options[:only] = Array(options[:only]) + [:name] if new_record?
    super(options)
  end
end
