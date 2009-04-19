require 'test_helper'

class TaggedItemTest < ActiveSupport::TestCase
  test "create should update balance on tag record" do
    initial_amount = tags(:john_lunch).balance
    events(:john_bill_pay).tagged_items.create({:tag => tags(:john_lunch), :amount => 1500}, :occurred_on => Date.today)
    assert_equal initial_amount + 1500, tags(:john_lunch, :reload).balance
  end

  test "destroy should update balance on tag record" do
    assert_not_equal 0, tags(:john_lunch).balance
    tagged_items(:john_lunch_lunch).destroy
    assert_equal 0, tags(:john_lunch, :reload).balance
  end
end
