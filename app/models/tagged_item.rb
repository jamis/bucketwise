class TaggedItem < ActiveRecord::Base
  include OptionHandler, Pageable

  belongs_to :event
  belongs_to :tag

  before_create :increment_tag_balance
  before_destroy :decrement_tag_balance

  def to_xml(options={})
    options[:except] = Array(options[:except])
    options[:except].concat [:id, :event_id, :occurred_on]
    options[:except] << :tag_id unless new_record?

    append_to_options(options, :include, :tag => { :except => :subscription_id })
    super(options)
  end

  protected

    def increment_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance + #{amount} WHERE id = #{tag_id}"
    end

    def decrement_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance - #{amount} WHERE id = #{tag_id}"
    end
end
