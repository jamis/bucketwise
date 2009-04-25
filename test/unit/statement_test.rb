require 'test_helper'

class StatementTest < ActiveSupport::TestCase
  test "creation with ending balance as dollars should be translated to cents" do
    statement = accounts(:john_checking).statements.create(:occurred_on => Date.today,
      :ending_balance => "1,234.56")
    assert_equal 1_234_56, statement.ending_balance
  end

  test "creation with cleared ids should set statement id for given account items" do
    items = [:john_checking_starting_balance, :john_bill_pay_checking].map { |i| account_items(i).id }

    statement = accounts(:john_checking).statements.create(
      :occurred_on => Date.today, :ending_balance => 1_234_56, :cleared => items)

    assert_equal items, statement.account_items.map(&:id)
  end

  test "creation with cleared ids should filter out items for different accounts" do
    items = [:john_checking_starting_balance, :john_bill_pay_checking].map { |i| account_items(i).id }
    bad_items = items + [account_items(:john_lunch_mastercard).id]

    statement = accounts(:john_checking).statements.create(
      :occurred_on => Date.today, :ending_balance => 1_234_56, :cleared => bad_items)

    assert_equal items, statement.account_items.map(&:id)
  end

  test "balanced_at should not be set when no items have been given" do
    statement = accounts(:john_checking).statements.create(:occurred_on => Date.today,
      :ending_balance => 1_234_56)
    assert_nil statement.balanced_at
  end

  test "balanced_at should be set automatically when items all balance" do
    statements(:john).destroy # get this one out of the way

    items = [:john_checking_starting_balance, :john_bill_pay_checking].map { |i| account_items(i).id }

    statement = accounts(:john_checking).statements.create(
      :occurred_on => Date.today, :ending_balance => 992_25, :cleared => items)

    assert_not_nil statement.balanced_at
    assert (Time.now - statement.balanced_at) < 1
  end

  test "balanced_at should be cleared automatically when items do not balance" do
    items = [:john_checking_starting_balance, :john_bill_pay_checking].map { |i| account_items(i).id }

    statement = accounts(:john_checking).statements.create(:occurred_on => Date.today,
      :ending_balance => 1_234_56)
    statement.balanced_at = Time.now.utc
    statement.save

    assert_not_nil statement.reload.balanced_at

    statement.update_attributes :cleared => items
    assert_nil statement.reload.balanced_at
  end

  test "deleting statement should nullify association with account items" do
    assert statements(:john).account_items.any?
    assert_equal statements(:john), account_items(:john_checking_starting_balance).statement

    assert_difference "Statement.count", -1 do
      assert_no_difference "AccountItem.count" do
        statements(:john).destroy
      end
    end

    assert_nil account_items(:john_checking_starting_balance, :reload).statement
  end

  test "balanced should be true when unsettled balance is zero" do
    assert statements(:john).balanced?
    statements(:john).update_attributes :ending_balance => 1234_56,
      :cleared => statements(:john).account_items.map(&:id)
    assert !statements(:john).balanced?(true)
  end
end
