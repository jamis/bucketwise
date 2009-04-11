class Event < ActiveRecord::Base
  belongs_to :subscription
  belongs_to :user

  has_many :line_items, :dependent => :destroy do
    def for_role(name)
      name = name.to_s
      to_a.select { |item| item.role == name }
    end
  end

  has_many :account_items, :dependent => :destroy

  has_many :tagged_items, :dependent => :destroy do
    def partial
      @partial ||= to_a.select { |item| item.amount != @owner.value }
    end

    def whole
      @whole ||= to_a.select { |item| item.amount == @owner.value }
    end
  end

  has_many :tags, :through => :tagged_items

  alias_method :original_line_items_assignment, :line_items=
  alias_method :original_tagged_items_assignment, :tagged_items=

  attr_accessible :occurred_on, :actor, :check_number, :memo
  attr_accessible :line_items, :tagged_items, :role

  after_save :realize_line_items, :realize_tagged_items

  def balance
    @balance ||= account_items.sum(:amount) || 0
  end

  # Like balance, but always shows the absolute value of an event. Whereas
  # balance will be 0 for a transfer, value will be the amount transferred.
  # An expense will give a negative balance, but value will be the absolute
  # value of that.
  def value
    case role
    when :expense, :deposit then balance.abs
    when :transfer then account_items.first.amount.abs
    when :reallocation then line_items.for_role(:primary).first.amount.abs
    else raise "cannot compute value of line item with role #{role.inspect}"
    end
  end

  def account_for(role)
    role = role.to_s
    item = line_items.detect { |item| item.role == role }
    return item ? item.account : nil
  end

  def line_items=(list)
    if list.any? { |item| item.is_a?(Hash) }
      @line_items_to_realize = list
    else
      original_line_items_assignment(list)
    end
  end

  def tagged_items=(list)
    if list.any? { |item| item.is_a?(Hash) }
      @tagged_items_to_realize = list
    else
      original_tagged_items_assignment(list)
    end
  end

  def role=(role)
    unless %w(deposit expense reallocation transfer).include?(role.to_s)
      raise ArgumentError, "invalid role: #{role.inspect}"
    end

    @role = role.to_sym
  end

  def role
    @role ||= if balance > 0
        :deposit
      elsif balance < 0
        :expense
      elsif account_items.length == 1
        :reallocation
      else
        :transfer
      end
  end

  protected

    def realize_line_items
      if @line_items_to_realize
        line_items.destroy_all
        account_items.destroy_all

        summaries = Hash.new(0)
        @line_items_to_realize.each do |item|
          account = subscription.accounts.find(item[:account_id])

          bucket_id = item.delete(:bucket_id)
          item[:bucket] = if bucket_id =~ /^n:(.*)/
            account.buckets.find_by_name($1) || account.buckets.create_for(user, :name => $1)
          elsif bucket_id =~ /^r:(.*)/
            account.buckets.for_role($1, user)
          else
            account.buckets.find(bucket_id)
          end

          item = line_items.create(item.merge(:occurred_on => occurred_on))
          summaries[account] += item.amount
        end

        summaries.each do |account, amount|
          account_items.create(:account => account,
            :amount => amount, :occurred_on => occurred_on)
        end

        @line_items_to_realize = nil
      end
    end

    def realize_tagged_items
      if @tagged_items_to_realize
        tagged_items.destroy_all

        @tagged_items_to_realize.each do |item|
          if item[:tag_id] =~ /^n:(.*)/
            item[:tag_id] = subscription.tags.find_or_create_by_name($1).id
          else
            subscription.tags.find(item[:tag_id])
          end

          tagged_items.create(item.merge(:occurred_on => occurred_on))
        end

        @tagged_items_to_realize = nil
      end
    end
end
