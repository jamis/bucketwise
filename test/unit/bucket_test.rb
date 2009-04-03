require 'test_helper'

class BucketTest < ActiveSupport::TestCase
  test "assimilate should change all references of argument to self and destroy argument" do
    groceries = buckets(:john_checking_groceries)
    dining = buckets(:john_checking_dining)
    old_groceries_balance = groceries.balance
    old_dining_balance = dining.balance

    groceries.assimilate(dining)

    assert !Bucket.exists?(dining.id)
    assert_equal groceries, line_items(:john_lunch_checking_dining).bucket
    assert_equal buckets(:john_checking_groceries, :reload).balance, old_groceries_balance + old_dining_balance
  end

  test "assimilate bucket from different account should raise exception and make no change" do
    groceries = buckets(:john_checking_groceries)
    general = buckets(:john_mastercard_general)

    assert_raise ArgumentError do
      groceries.assimilate(general)
    end

    assert Bucket.exists?(general.id)
    assert_equal general, line_items(:john_lunch_mastercard).bucket
  end

  test "assimilate self should raise exception and make no change" do
    groceries = buckets(:john_checking_groceries)

    assert_no_difference "Bucket.count" do
      assert_raise ArgumentError do
        groceries.assimilate(groceries)
      end
    end
  end
end
