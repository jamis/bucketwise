require 'test_helper'

class TagTest < ActiveSupport::TestCase
  test "assimilate should raise exception when argument is same as self" do
    assert_no_difference "Tag.count" do
      assert_raise(ActiveRecord::RecordNotSaved) do
        tags(:john_lunch).assimilate(tags(:john_lunch))
      end
    end

    assert_equal tags(:john_lunch), tagged_items(:john_lunch_lunch).tag
  end

  test "assimilate should update all tagged items of argument to refer to self" do
    items = tags(:john_lunch).tagged_items
    assert items.any?

    tags(:john_fuel).assimilate(tags(:john_lunch))
    assert items.all? { |item| item.reload.tag == tags(:john_fuel) }
  end

  test "assimilate should update balance to include amounts of tagged items" do
    balance = tags(:john_fuel).balance
    tags(:john_fuel).assimilate(tags(:john_lunch))

    assert_equal balance + tags(:john_lunch).balance, tags(:john_fuel).balance
    assert_equal balance + tags(:john_lunch).balance, tags(:john_fuel, :reload).balance
  end

  test "assimilate should destroy argument but not tagged items" do
    items = tags(:john_lunch).tagged_items
    assert items.any?

    tags(:john_fuel).assimilate(tags(:john_lunch))
    assert !Tag.exists?(tags(:john_lunch).id)
    assert items.all? { |item| TaggedItem.exists?(item.id) }
  end

  test "duplicates should be allowed for different subscriptions" do
    assert_difference "Tag.count" do
      subscriptions(:tim).tags.create(:name => "lunch")
    end
  end

  test "duplicates should be forbidden within a subscription" do
    assert_no_difference "Tag.count" do
      tag = subscriptions(:john).tags.create(:name => "lunch")
      assert tag.errors.on(:name)
    end
  end
end
