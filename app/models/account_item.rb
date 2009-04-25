# AccountItems are almost the same as LineItems. However, a single Event may have
# multiple LineItems associated with the same account (think "split transactions"),
# and querying and aggregating those to show activity in an account would be more
# work than it really needs to be. AccountItems are basically an optimization that
# lets us show that activity more easily; each event will have exactly one AccountItem
# record for each Account that the Event references.

class AccountItem < ActiveRecord::Base
  include Pageable

  belongs_to :event
  belongs_to :account
  belongs_to :statement

  after_create :increment_balance
  before_destroy :decrement_balance

  named_scope :uncleared, lambda { |*args| AccountItem.options_for_uncleared(*args) }
  
  def self.options_for_uncleared(*args)
    raise ArgumentError, "too many arguments #{args.length} for 1" if args.length > 1

    options = args.first || {}
    raise ArgumentError, "expected Hash, got #{options.class}" unless options.is_a?(Hash)
    options = options.dup

    conditions = "statement_id IS NULL"
    parameters = []

    if options[:with]
      conditions = "(#{conditions} OR statement_id = ?)"
      parameters << options[:with]
    end

    { :conditions => [conditions, *parameters], :include => options[:include] }
  end

  protected

    def increment_balance
      account.update_attribute :balance, account.balance + amount
    end

    def decrement_balance
      account.update_attribute :balance, account.balance - amount
    end
end
