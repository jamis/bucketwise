# AccountItems are almost the same as LineItems. However, a single Event may have
# multiple LineItems associated with the same account (think "split transactions"),
# and querying and aggregating those to show activity in an account would be more
# work than it really needs to be. AccountItems are basically an optimization that
# lets us show that activity more easily; each event will have exactly one AccountItem
# record for each Account that the Event references.

class AccountItem < ActiveRecord::Base
  belongs_to :event
  belongs_to :account

  after_create :increment_balance
  before_destroy :decrement_balance

  protected

    def increment_balance
      account.update_attribute :balance, account.balance + amount
    end

    def decrement_balance
      account.update_attribute :balance, account.balance - amount
    end
end
