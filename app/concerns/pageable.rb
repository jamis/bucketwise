module Pageable
  DEFAULT_PAGE_SIZE = 100

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def page(n, options={})
      n = n.to_i
      size = (options[:size] || DEFAULT_PAGE_SIZE).to_i

      records = includes(:event => :line_items)
        .order("occurred_on DESC")
        .limit(size + 1)
        .offset(n * size)

      [records.length > size, records[0,size]]
    end
  end
end
