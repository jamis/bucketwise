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

  validates_presence_of :actor, :occurred_on
  validate :line_item_validations

  attr_accessor :amount

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

  def to_xml(options={})
    methods = Array(options[:methods])
    methods << :amount if amount

    except = Array(options[:except])
    if new_record?
      except += [:created_at, :subscription_id, :updated_at, :user_id]

      if line_items.empty?
        case role
        when :deposit then
          line_items.build(:role => "deposit", :amount => 1000)
        when :expense then
          line_items.build(:role => "payment_source", :amount => -1000)
          line_items.build(:role => "credit_options", :amount => -1000)
          line_items.build(:role => "aside", :amount => 1000)
        when :reallocation then
          line_items.build(:role => 'primary')
          line_items.build(:role => 'reallocate_from | reallocate_to')
        when :transfer then
          line_items.build(:role => 'transfer_from', :amount => -1000)
          line_items.build(:role => 'transfer_to', :amount => 1000)
        end
      end

      if tagged_items.empty?
        tagged_items.build
      end
    end

    super(options.merge(:methods => methods, :except => except))
  end

  protected

    def line_item_validations
      if @line_items_to_realize
        if @line_items_to_realize.empty?
          errors.add(:line_items, "must be provided")
        else
          ensure_line_item_roles_are_valid
          role = ensure_line_items_use_consistent_roles
          
          case role
          when :expense then ensure_expense_is_valid
          when :deposit then ensure_deposit_is_valid
          when :transfer then ensure_transfer_is_valid
          when :reallocation then ensure_reallocation_is_valid
          end
        end
      elsif new_record?
        errors.add(:line_items, "must be provided")
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
            account.buckets.find_by_name($1) || account.buckets.create({:name => $1}, :author => user)
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

          tagged_items.create(item, :occurred_on => occurred_on)
        end

        @tagged_items_to_realize = nil
      end
    end

  private

    ROLE_FROM_LINE_ITEM = {
      "payment_source"  => :expense,
      "credit_options"  => :expense,
      "aside"           => :expense,
      "deposit"         => :deposit,
      "transfer_from"   => :transfer,
      "transfer_to"     => :transfer,
      "reallocate_from" => :reallocation,
      "reallocate_to"   => :reallocation
    }

    def ensure_line_item_roles_are_valid
      @line_items_to_realize.each do |item|
        if item[:role].blank?
          errors.add(:line_item, "is missing the required `role' attribute")
          return false
        elsif !LineItem::VALID_ROLES.include?(item[:role].to_s)
          errors.add(:line_item, "contains unrecognized role #{item[:role].inspect}")
          return false
        end
      end

      return true
    end

    def ensure_line_items_use_consistent_roles
      roles = @line_items_to_realize.map { |item| item[:role].to_s }
      primary = roles.select { |role| role == "primary" }

      if primary.length > 1
        errors.add :line_items,
          "may include at most one `primary' role (#{primary.length} found)"
        return false
      end

      aside = roles.select { |role| role == "aside" }

      if aside.length > 1
        errors.add :line_items,
          "may include at most one `aside' role (#{aside.length} found)"
        return false
      end

      discriminant = roles.detect { |role| role != "primary" }

      if discriminant.nil?
        errors.add :line_items, "must include at least one non-primary role"
        return false
      end

      illegal = roles - (LineItem::VALID_ROLE_GROUPS[discriminant] || [])

      if illegal.any?
        errors.add :line_items, "include mismatched roles: " +
          "#{discriminant.inspect} cannot accompany #{illegal.inspect}"
        return false
      end

      return ROLE_FROM_LINE_ITEM[discriminant]
    end

    def ensure_expense_is_valid
      unless @line_items_to_realize.any? { |item| item[:role].to_s == "payment_source" }
        errors.add :line_items, "must include a payment_source role for expense scenarios"
        return false
      end

      payment = credit = aside = 0
      @line_items_to_realize.each do |item|
        case item[:role].to_s
        when "payment_source" then payment += item[:amount].to_i
        when "credit_options" then credit += item[:amount].to_i
        when "aside"          then aside += item[:amount].to_i
        end
      end

      if payment >= 0
        errors.add :line_items, "in payment_source role must have a negative amount"
        return false
      elsif @line_items_to_realize.any? { |item| item[:role].to_s == "credit_options" }
        if credit >= 0
          errors.add :line_items, "in credit_options role must have a negative amount"
          return false
        elsif aside <= 0
          errors.add :line_items, "in aside role must have a positive amount"
          return false
        elsif payment != credit
          errors.add :line_items, "for payment_source and credit_options must sum to identical balance"
          return false
        elsif payment.abs != aside
          errors.add :line_items, "for payment_source and aside must balance"
          return false
        end
      end

      return true
    end

    def ensure_deposit_is_valid
      if @line_items_to_realize.any? { |item| item[:amount].to_i <= 0 }
        errors.add :line_items, "for deposit must all have positive amounts"
        return false
      end

      return true
    end

    def ensure_transfer_is_valid
      roles = @line_items_to_realize.map { |item| item[:role].to_s }.uniq.sort
      if roles != %w(transfer_from transfer_to)
        errors.add :line_items, "must contain both transfer_from and transfer_to roles in a transfer scenario"
        return false
      end

      accounts = @line_items_to_realize.map { |item| item[:account_id].to_i }
      if accounts.uniq.length != 2
        errors.add :line_items, "must reference exactly two accounts in a transfer scenario"
        return false
      end

      balances = @line_items_to_realize.inject(Hash.new(0)) do |map, item|
        map[item[:account_id].to_i] += item[:amount].to_i
        map
      end

      if balances.values.sum != 0
        errors.add :line_items, "must have a zero balance in a transfer scenario"
        return false
      end

      @line_items_to_realize.each do |item|
        if item[:role].to_s == "transfer_from" && item[:amount].to_i >= 0
          errors.add :line_item, "with transfer_from role must have a negative amount"
          return false
        elsif item[:role].to_s == "transfer_to" && item[:amount].to_i <= 0
          errors.add :line_item, "with transfer_to role must have a positive amount"
          return false
        end
      end

      return true
    end

    def ensure_reallocation_is_valid
      unless @line_items_to_realize.any? { |item| item[:role].to_s == "primary" }
        errors.add :line_items, "must include a `primary' role for bucket reallocation scenario"
        return false
      end

      accounts = @line_items_to_realize.map { |item| item[:account_id].to_i }.uniq
      if accounts.length != 1
        errors.add :line_items,
          "for bucket reallocation scenario must reference exactly one account"
        return false
      end

      balances = @line_items_to_realize.inject(Hash.new(0)) do |map, item|
        map[item[:role]] += item[:amount].to_i
        map
      end

      if balances.values.sum != 0
        errors.add :line_items, "must balance to zero for bucket reallocation scenario"
        return false
      end

      return true
    end
end
