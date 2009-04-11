class Tag < ActiveRecord::Base
  DEFAULT_PAGE_SIZE = 100

  belongs_to :subscription

  has_many :tagged_items, :dependent => :delete_all do
    def page(n, options={})
      size = options.fetch(:size, DEFAULT_PAGE_SIZE)
      records = find(:all, :include => { :event => :line_items },
        :order => "occurred_on DESC",
        :limit => size + 1,
        :offset => n * size)

      [records.length > size, records[0,size]]
    end
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
end
