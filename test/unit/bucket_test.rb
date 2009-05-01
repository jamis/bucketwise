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

  test "blank names should be disallowed" do
    assert_no_difference "Bucket.count" do
      bucket = accounts(:john_checking).buckets.create(
        { :name => "", :role => "" },
        :author => users(:john))

      assert bucket.errors.on(:name)
    end
  end

  test "duplicate names are allowed for different accounts" do
    assert_difference "Bucket.count" do
      bucket = accounts(:john_savings).buckets.create(
        { :name => buckets(:john_checking_dining).name, :role => "" },
        :author => users(:john))

      assert bucket.errors.on(:name).blank?
    end
  end

  test "duplicate names are disallowed within the same account" do
    assert_no_difference "Bucket.count" do
      bucket = accounts(:john_checking).buckets.create(
        { :name => buckets(:john_checking_dining).name, :role => "" },
        :author => users(:john))

      assert bucket.errors.on(:name)
    end
  end

  test "balance should read computed_balance if that value is set" do
    filter = QueryFilter.new(:expenses => true)
    dining = accounts(:john_checking).buckets.filter(filter).find(:first, :conditions => { :name => "Dining" })
    assert dining[:computed_balance]
    assert_not_equal dining[:balance], dining[:computed_balance]
    assert_equal dining[:computed_balance].to_i, dining.balance
  end
end
