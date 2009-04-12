require 'test_helper'

class AccountTest < ActiveSupport::TestCase
  test "create should also create default bucket" do
    assert_difference "Bucket.count" do
      a = new_account
      assert_equal %w(default), a.buckets.map(&:role)
      assert_equal a.author, a.buckets.first.author
    end
  end

  test "create without starting balance should initialize with zero items" do
    assert_no_difference "Event.count" do
      a = new_account
      assert a.line_items.count.zero?
      assert a.account_items.count.zero?
      assert a.balance.zero?
    end
  end

  test "create with starting balance should initialize balance" do
    assert_difference "subscriptions(:john).events.count" do
      a = new_account :starting_balance => {
        :occurred_on => 1.week.ago.utc, :amount => "12345" }
      assert_equal [a.buckets.default], a.line_items.map(&:bucket)
      assert_equal 12345, a.balance
    end
  end

  test "create duplicate account should fail" do
    assert_no_difference "Account.count" do
      account = new_account :name => accounts(:john_checking).name.upcase
      assert !account.valid?
      assert account.new_record?
    end
  end

  test "duplicates should be scoped to subscription" do
    assert_difference "Account.count" do
      account = new_account :subscription => subscriptions(:tim), :name => accounts(:john_savings).name
      assert account.valid?
    end
  end

  test "create with blank name should fail" do
    assert_no_difference "Account.count" do
      account = new_account :name => ""
      assert !account.valid?
      assert account.new_record?
    end
  end

  test "available balance should be the same as balance when there is no aside" do
    assert !accounts(:john_savings).buckets.detect { |bucket| bucket.role == 'aside' }
    assert_equal accounts(:john_savings).available_balance, accounts(:john_savings).balance
  end

  test "unavailable balance should exclude aside balance" do
    checking = accounts(:john_checking)
    aside = buckets(:john_checking_aside)
    assert !aside.balance.zero?
    assert_equal checking.available_balance, checking.balance - aside.balance
  end

  test "destroy should remove all line items referencing this account" do
    accounts(:john_mastercard).destroy
    assert !Account.exists?(accounts(:john_mastercard).id)
    assert LineItem.find(:all, :conditions => { :account_id => accounts(:john_mastercard).id }).empty?
  end

  test "destroy should remove all account items referencing this account" do
    accounts(:john_mastercard).destroy
    assert !Account.exists?(accounts(:john_mastercard).id)
    assert AccountItem.find(:all, :conditions => { :account_id => accounts(:john_mastercard).id }).empty?
  end

  test "destroy should remove all buckets referencing this account" do
    accounts(:john_mastercard).destroy
    assert !Account.exists?(accounts(:john_mastercard).id)
    assert Bucket.find(:all, :conditions => { :account_id => accounts(:john_mastercard).id }).empty?
  end

  test "destroy should remove all events referencing only this account" do
    assert Event.exists?(events(:john_bare_mastercard).id)
    assert Event.exists?(events(:john_lunch).id)
    assert Event.exists?(events(:john_bill_pay).id)
    accounts(:john_mastercard).destroy
    assert !Event.exists?(events(:john_bare_mastercard).id)
    assert Event.exists?(events(:john_lunch).id)
    assert Event.exists?(events(:john_bill_pay).id)
  end

  test "destroy should remove all tagged items for events referencing only this account" do
    assert_equal 1500, tags(:john_fuel).balance
    accounts(:john_mastercard).destroy
    assert_equal 0, tags(:john_fuel, :reload).balance
  end

  private

    def new_account(options={})
      subscription = options.delete(:subscription) || subscriptions(:john)

      options = {:name => "Visa",
                 :role => "credit-card"}.merge(options)

      subscription.accounts.create_for(users(:john), options)
    end
end
