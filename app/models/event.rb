class Event < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :user

  has_many :line_items, :dependent => :destroy
  has_many :account_items, :dependent => :destroy

  alias_method :original_line_items_assignment, :line_items=

  after_create :realize_line_items

  def balance
    @balance ||= account_items.sum(:amount) || 0
  end

  def line_items=(list)
    if list.any? { |item| item.is_a?(Hash) }
      @line_items_to_realize = list
    else
      original_line_items_assignment(list)
    end
  end

  protected

    def realize_line_items
      if @line_items_to_realize
        line_items.destroy_all

        summaries = Hash.new(0)
        @line_items_to_realize.each do |item|
          account = subscription.accounts.find(item[:account_id])

          if item[:bucket_id] =~ /^n:(.*)/
            item[:bucket_id] = account.buckets.find_or_create_by_name(:name => $1, :author => user).id
          elsif item[:bucket_id] =~ /^r:(.*)/
            item[:bucket_id] = account.buckets.for_role($1, user).id
          else
            account.buckets.find(item[:bucket_id])
          end

          item = line_items.create(item.merge(:occurred_on => occurred_on))
          summaries[item.account_id] += item.amount
        end

        summaries.each do |account_id, amount|
          account_items.create(:account_id => account_id,
            :amount => amount, :occurred_on => occurred_on)
        end

        @line_items_to_realize = nil
      end
    end
end
