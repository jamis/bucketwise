require 'test_helper'

class AccountItemTest < ActiveSupport::TestCase
  test "create should update balance on account record" do
    initial_amount = accounts(:john_checking).balance

    subscriptions(:john).events.where(:user => users(:john)).create({:occurred_on => 3.days.ago.to_date,
      :actor_name => "Something",
      :line_items => [
        { :account_id => accounts(:john_checking).id,
          :bucket_id  => buckets(:john_checking_groceries).id,
          :amount     => -25_75,
          :role       => 'payment_source' },
      ]
    })

    assert_equal initial_amount - 25_75, accounts(:john_checking, :reload).balance
  end

  test "destroy should update balance on account record" do
    amount = account_items(:john_lunch_checking).amount
    current = accounts(:john_checking).balance
    account_items(:john_lunch_checking).destroy
    assert_equal current - amount, accounts(:john_checking, :reload).balance
  end
end
