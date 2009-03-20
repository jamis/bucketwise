class Tag < ActiveRecord::Base
  DEFAULT_PAGE_SIZE = 100

  belongs_to :subscription

  has_many :tagged_items do
    def page(n, options={})
      size = options.fetch(:size, DEFAULT_PAGE_SIZE)
      records = find(:all, :include => { :event => :line_items },
        :order => "occurred_on DESC",
        :limit => size + 1,
        :offset => n * size)

      [records.length > size, records[0,size]]
    end
  end
end
