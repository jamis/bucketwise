require 'test_helper'

class LineItemTest < ActiveSupport::TestCase
  test "create should update balance on bucket record" do
    initial_amount = buckets(:john_checking_groceries).balance

    subscriptions(:john).events.create(:occurred_on => 3.days.ago.to_date,
        :actor => "Something", :user => users(:john),
        :line_items => [
          { :account_id => accounts(:john_checking).id,
            :bucket_id  => buckets(:john_checking_groceries).id,
            :amount     => -25_75,
            :role       => 'payment_source' },
        ])

    assert_equal initial_amount - 25_75, buckets(:john_checking_groceries, :reload).balance
  end

  test "destroy should update balance on bucket record" do
    amount = line_items(:john_lunch_checking_dining).amount
    current = buckets(:john_checking_dining).balance
    line_items(:john_lunch_checking_dining).destroy
    assert_equal current - amount, buckets(:john_checking_dining, :reload).balance
  end
end
