class TaggedItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :tag

  before_create :increment_tag_balance
  before_destroy :decrement_tag_balance

  protected

    def increment_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance + #{amount} WHERE id = #{tag_id}"
    end

    def decrement_tag_balance
      Tag.connection.update "UPDATE tags SET balance = balance - #{amount} WHERE id = #{tag_id}"
    end
end
