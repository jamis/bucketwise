require 'test_helper'

class EventTest < ActiveSupport::TestCase
  # self.use_transactional_fixtures = false

  setup :prepare_basic_event_data

  test "create with nonexistant account-id should fail" do
    assert !Account.exists?(12345)
    @event_base[:line_items][0][:account_id] = 12345
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.where(:user => users(:john)).create(@event_base)
      end
    end
  end

  test "create with inaccessible account-id should fail" do
    @event_base[:line_items][0][:account_id] = accounts(:tim_checking).id
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      end
    end
  end

  test "create with nonexistant bucket-id should fail" do
    assert !Bucket.exists?(12345)
    @event_base[:line_items][0][:bucket_id] = 12345
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      end
    end
  end

  test "create with inaccessible bucket-id should fail" do
    @event_base[:line_items][0][:bucket_id] = buckets(:tim_checking_general).id
    assert_no_difference "Event.count" do
      assert_raise(ActiveRecord::RecordNotFound) do
        subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      end
    end
  end

  test "create without actor should not pass validation" do
    @event_base.delete(:actor_name)
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:actor_name)
    end
  end

  test "create with blank actor should not pass validation" do
    @event_base[:actor_name] = ""
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:actor_name)
    end
  end

  test "create without occurred_on should not pass validation" do
    @event_base.delete(:occurred_on)
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:occurred_on)
    end
  end

  test "create without line items should not pass validation" do
    @event_base.delete(:line_items)
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create with empty line items should not pass validation" do
    @event_base[:line_items] = []
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create with unrecognized event role should fail validation" do
    @event_base[:line_items][0][:role] = "bogus"
    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_item)
    end
  end

  test "create with mismatched line item roles should fail validation" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'transfer_from' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_dining).id,
        :amount     => 25_75,
        :role       => 'deposit' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create transfer with only a single account should not pass validation" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'transfer_from' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_dining).id,
        :amount     => 25_75,
        :role       => 'transfer_to' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create transfer without balancing amounts should not pass validation" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'transfer_from' },
      { :account_id => accounts(:john_savings).id,
        :bucket_id  => buckets(:john_savings_general).id,
        :amount     => 26_75,
        :role       => 'transfer_to' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create transfer should have correct sign for balance of from and to accounts" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => 25_75,
        :role       => 'transfer_from' },
      { :account_id => accounts(:john_savings).id,
        :bucket_id  => buckets(:john_savings_general).id,
        :amount     => -25_75,
        :role       => 'transfer_to' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_item)
    end
  end

  test "create expense with repayment options should require amounts to balance" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'payment_source' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_aside).id,
        :amount     => 25_76,
        :role       => 'aside' },
      { :account_id => accounts(:john_mastercard).id,
        :bucket_id  => buckets(:john_mastercard_general).id,
        :amount     => -25_75,
        :role       => 'credit_options' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create expense with repayment options should include aside role" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'payment_source' },
      { :account_id => accounts(:john_mastercard).id,
        :bucket_id  => buckets(:john_mastercard_general).id,
        :amount     => -25_75,
        :role       => 'credit_options' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create expense should have negative balance for payment_source" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => 25_75,
        :role       => 'payment_source' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create expense should have negative balance for credit_options" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'payment_source' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_aside).id,
        :amount     => 25_75,
        :role       => 'aside' },
      { :account_id => accounts(:john_mastercard).id,
        :bucket_id  => buckets(:john_mastercard_general).id,
        :amount     => 25_75,
        :role       => 'credit_options' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create expense should have positive balance for aside" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -25_75,
        :role       => 'payment_source' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_aside).id,
        :amount     => -25_75,
        :role       => 'aside' },
      { :account_id => accounts(:john_mastercard).id,
        :bucket_id  => buckets(:john_mastercard_general).id,
        :amount     => -25_75,
        :role       => 'credit_options' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create deposit should have positive balance" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => -1500,
        :role       => 'deposit' },
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create bucket reallocation with multiple accounts should not pass validation" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => 25_75,
        :role       => 'primary' },
      { :account_id => accounts(:john_savings).id,
        :bucket_id  => buckets(:john_savings_general).id,
        :amount     => -25_75,
        :role       => 'reallocate_from' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create bucket reallocation without balancing amounts should not pass validation" do
    @event_base[:line_items] = [
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_groceries).id,
        :amount     => 25_75,
        :role       => 'primary' },
      { :account_id => accounts(:john_checking).id,
        :bucket_id  => buckets(:john_checking_dining).id,
        :amount     => -35_75,
        :role       => 'reallocate_from' }
    ]

    assert_no_difference "Event.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
      assert event.errors.include?(:line_items)
    end
  end

  test "create with existing buckets should associate line items with those buckets" do
    event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
    assert_equal [-25_75, -15_25], event.line_items.map(&:amount)
    assert_equal [buckets(:john_checking_groceries), buckets(:john_checking_household)], event.line_items.map(&:bucket)
    assert buckets(:john_checking_groceries, :reload).updated_at > 1.second.ago.utc
    assert buckets(:john_checking_household, :reload).updated_at > 1.second.ago.utc
  end

  test "create with buckets by name should find or create buckets as needed" do
    @event_base[:line_items][0][:bucket_id] = "n:Dining"
    @event_base[:line_items][1][:bucket_id] = "n:Gambling"
    assert_difference "accounts(:john_checking).buckets.count" do
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
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
      event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
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

    event = subscriptions(:john).events.where(user: users(:john)).create(@event_base)
    assert_equal [["Checking", 0], ["Mastercard", -25_00]],
      event.account_items.map { |i| [i.account.name, i.amount] }.sort
  end

  test "create with tagged_items should generate tagged_items for event" do
    event = subscriptions(:john).events.where(:user => users(:john)).create(@event_base.merge(
        :tagged_items => [ { :tag_id => tags(:john_lunch).id, :amount => 500 } ]))
    assert_equal 1, event.tagged_items.length
    assert_equal [500], event.tagged_items.map(&:amount)
    assert_equal [tags(:john_lunch)], event.tagged_items.map(&:tag)
  end

  test "create with named tagged_items should find or create tagged_items" do
    event = subscriptions(:john).events.where(:user => users(:john)).create(@event_base.merge(
        :tagged_items => [ { :tag_id => "n:milk", :amount => 500 },
                           { :tag_id => "n:fruit", :amount => 750 } ]))
    assert_equal 2, event.tagged_items.length
    assert_equal [500, 750], event.tagged_items.map(&:amount)
    milk = subscriptions(:john).tags.detect { |t| t.name == "milk" }
    fruit = subscriptions(:john).tags.detect { |t| t.name == "fruit" }
    assert_equal [milk, fruit], event.tagged_items.map(&:tag)
  end

  test "update without line items should leave exising line items alone" do
    events(:john_lunch).update :actor_name => "Somebody Else"
    assert_equal "Somebody Else", events(:john_lunch, :reload).actor_name
    assert events(:john_lunch).line_items.any?
  end

  test "update with line items should replace all line items with those given" do
    items = events(:john_lunch).line_items.to_a

    events(:john_lunch).update :actor_name => "Somebody Else",
      :line_items => [
        { :account_id => accounts(:john_savings).id,
          :bucket_id => buckets(:john_savings_general).id,
          :amount => -200_00,
          :role => "payment_source" }]

    assert !items.any? { |item| LineItem.exists?(item.id) }
    assert_equal -200_00, events(:john_lunch, :reload).balance
  end

  test "update without tagged items should leave exising tagged items alone" do
    events(:john_lunch).update :actor_name => "Somebody Else"
    assert_equal "Somebody Else", events(:john_lunch, :reload).actor_name
    assert events(:john_lunch).tagged_items.any?
  end

  test "update with tagged items should replace tagged line items with those given" do
    items = events(:john_lunch).tagged_items.to_a

    events(:john_lunch).update :actor_name => "Somebody Else",
      :tagged_items => [{ :tag_id => "n:testing", :amount => 311}]

    assert !items.any? { |item| TaggedItem.exists?(item.id) }
    assert_equal [311], events(:john_lunch, :reload).tagged_items.map(&:amount)
  end

  test "destroy should remove event's line items, account_items, and tagged_items" do
    line_items = events(:john_lunch).line_items.to_a
    account_items = events(:john_lunch).account_items.to_a
    tagged_items = events(:john_lunch).tagged_items.to_a

    assert line_items.any?
    assert account_items.any?
    assert tagged_items.any?

    events(:john_lunch).destroy

    assert !line_items.any? { |item| LineItem.exists?(item.id) }
    assert !account_items.any? { |item| AccountItem.exists?(item.id) }
    assert !tagged_items.any? { |item| TaggedItem.exists?(item.id) }
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
        :actor_name => "Something",
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
