require 'test_helper'

class EventTest < ActiveSupport::TestCase
  self.use_transactional_fixtures = false

  setup :prepare_basic_event_data

  test "create with nonexistant account-id should fail" do
    assert !Account.exists?(12345)
    @event_base[:line_items][0][:account_id] = 12345
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.create(@event_base)
      end
    end
  end

  test "create with inaccessible account-id should fail" do
    @event_base[:line_items][0][:account_id] = accounts(:tim_checking).id
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.create(@event_base)
      end
    end
  end

  test "create with nonexistant bucket-id should fail" do
    assert !Bucket.exists?(12345)
    @event_base[:line_items][0][:bucket_id] = 12345
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.create(@event_base)
      end
    end
  end

  test "create with inaccessible bucket-id should fail" do
    @event_base[:line_items][0][:bucket_id] = buckets(:tim_checking_general).id
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.create(@event_base)
      end
    end
  end

  test "create with existing buckets should associate line items with those buckets" do
    event = subscriptions(:john).events.create(@event_base)
    assert_equal [-25_75, -15_25], event.line_items.map(&:amount)
    assert_equal [buckets(:john_checking_groceries), buckets(:john_checking_household)], event.line_items.map(&:bucket)
  end

  test "create with buckets by name should find or create buckets as needed" do
    @event_base[:line_items][0][:bucket_id] = "n:Dining"
    @event_base[:line_items][1][:bucket_id] = "n:Gambling"
    assert_difference "accounts(:john_checking).buckets.count" do
      event = subscriptions(:john).events.create(@event_base)
      assert_equal [-25_75, -15_25], event.line_items.map(&:amount)
      gambling = accounts(:john_checking).buckets.detect { |b| b.name == "Gambling" }
      assert gambling
      assert gambling.role.blank?
      assert_equal [buckets(:john_checking_dining), gambling], event.line_items.map(&:bucket)
    end
  end

  test "create with buckets by role should find or create buckets as needed" do
    @event_base[:line_items][0][:bucket_id] = "r:default"
    @event_base[:line_items][1][:bucket_id] = "r:custom"
    assert_difference "accounts(:john_checking).buckets.count" do
      event = subscriptions(:john).events.create(@event_base)
      assert_equal [-25_75, -15_25], event.line_items.map(&:amount)
      custom = accounts(:john_checking).buckets.for_role("custom", users(:john))
      assert custom
      assert_equal "Custom", custom.name
      assert_equal [buckets(:john_checking_general), custom], event.line_items.map(&:bucket)
    end
  end

  test "create should generate account items for each referenced account" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_mastercard).id,
        :bucket_id  => buckets(:john_mastercard_general).id,
        :amount     => -25_00,
        :role       => 'payment_source' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_dining).id,
        :amount     => -25_00,
        :role       => 'credit_options' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_aside).id,
        :amount     => 25_00,
        :role       => 'aside' }
    ]

    event = subscriptions(:john).events.create(@event_base)
    assert_equal [-25_00, 0], event.account_items.map(&:amount)
    assert_equal [accounts(:john_mastercard), accounts(:john_checking)], event.account_items.map(&:account)
  end

  test "create with tagged_items should generate tagged_items for event" do
    event = subscriptions(:john).events.create(@event_base.merge(
      :tagged_items => [ { :tag_id => tags(:john_lunch).id, :amount => 500 } ]))
    assert_equal 1, event.tagged_items.length
    assert_equal [500], event.tagged_items.map(&:amount)
    assert_equal [tags(:john_lunch)], event.tagged_items.map(&:tag)
  end

  test "create with named tagged_items should find or create tagged_items" do
    event = subscriptions(:john).events.create(@event_base.merge(
      :tagged_items => [ { :tag_id => "n:milk", :amount => 500 },
                         { :tag_id => "n:fruit", :amount => 750 } ]))
    assert_equal 2, event.tagged_items.length
    assert_equal [500, 750], event.tagged_items.map(&:amount)
    milk = subscriptions(:john).tags.detect { |t| t.name == "milk" }
    fruit = subscriptions(:john).tags.detect { |t| t.name == "fruit" }
    assert_equal [milk, fruit], event.tagged_items.map(&:tag)
  end

  test "role for deposit event should be deposit" do
    assert_equal :deposit, events(:john_checking_starting_balance).role
  end

  test "role for expense event should be expense" do
    assert_equal :expense, events(:john_lunch).role
  end

  test "role for transfer event should be transfer" do
    assert_equal :transfer, events(:john_bill_pay).role
  end

  test "role for reallocation events should be reallocation" do
    assert_equal :reallocation, events(:john_reallocate_from).role
    assert_equal :reallocation, events(:john_reallocate_to).role
  end

  test "value for deposit should be the balance" do
    assert_equal events(:john_checking_starting_balance).balance,
      events(:john_checking_starting_balance).value
  end

  test "value for expense should be the absolute value of the balance" do
    assert_equal events(:john_lunch).balance.abs, events(:john_lunch).value
  end

  test "value for transfer should be the absolute value any one of the account items" do
    assert_equal events(:john_bill_pay).account_items.first.amount.abs,
      events(:john_bill_pay).value
  end

  test "value for reallocation should be the absolute value any one of the primary item" do
    assert_equal events(:john_reallocate_from).line_items.for_role(:primary).first.amount.abs,
      events(:john_reallocate_from).value
    assert_equal events(:john_reallocate_to).line_items.for_role(:primary).first.amount.abs,
      events(:john_reallocate_to).value
  end

  protected

    def prepare_basic_event_data
      @event_base = {
        :occurred_on => 3.days.ago.to_date,
        :actor => "Something",
        :user => users(:john),
        :line_items => [
          { :account_id => accounts(:john_checking).id,
            :bucket_id  => buckets(:john_checking_groceries).id,
            :amount     => -25_75,
            :role       => 'payment_source' },
          { :account_id => accounts(:john_checking).id,
            :bucket_id  => buckets(:john_checking_household).id,
            :amount     => -15_25,
            :role       => 'payment_source' }
        ]}
    end
end
