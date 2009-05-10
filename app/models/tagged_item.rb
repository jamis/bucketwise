class TaggedItem < ActiveRecord::Base
  include OptionHandler, Pageable

  belongs_to :event
  belongs_to :tag

  before_create :ensure_consistent_tag, :increment_tag_balance, :ensure_occurred_on
  before_destroy :decrement_tag_balance

  attr_accessible :tag, :tag_id, :amount

  delegate :name, :to => :tag

  def tag_id=(value)
    case value
    when Fixnum, /^\s*\d+\s*$/ then super(value)
    else @tag_to_translate = value
    end
  end

  def to_xml(options={})
    options[:except] = Array(options[:except])
    options[:except].concat [:event_id, :occurred_on]
    options[:except] << :tag_id unless new_record?

    append_to_options(options, :include, :tag => { :except => :subscription_id })
    super(options)
  end

  protected

    def ensure_consistent_tag
      if @tag_to_translate =~ /^n:(.*)/
        self.tag_id = event.subscription.tags.find_or_create_by_name($1).id
      else
        # make sure the given tag id exists in the given subscription
        event.subscription.tags.find(tag_id)
      end
    end

    def ensure_occurred_on
      self.occurred_on ||= event.occurred_on
    end

    def increment_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance + #{amount} WHERE id = #{tag_id}"
    end

    def decrement_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance - #{amount} WHERE id = #{tag_id}"
    end
end
