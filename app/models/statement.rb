class Statement < ActiveRecord::Base
  belongs_to :account
  has_many :account_items, :extend => CategorizedItems, :dependent => :nullify

  before_create :initialize_starting_balance
  after_save :associate_account_items_with_self

  named_scope :pending, :conditions => { :balanced_at => nil }
  named_scope :balanced, :conditions => "balanced_at IS NOT NULL"

  attr_accessible :occurred_on, :ending_balance, :cleared

  validates_presence_of :occurred_on, :ending_balance

  def ending_balance=(amount)
    if amount.is_a?(Float) || amount =~ /[.,]/
      amount = (amount.to_s.tr(",", "").to_f * 100).round
    end

    super(amount)
  end

  def balance
    ending_balance
  end

  def balanced?(reload=false)
    unsettled_balance(reload).zero?
  end

  def settled_balance(reload=false)
    @settled_balance = nil if reload
    @settled_balance ||= account_items.to_a.sum(&:amount)
  end

  def unsettled_balance(reload=false)
    @unsettled_balance = nil if reload
    @unsettled_balance ||= starting_balance + settled_balance(reload) - ending_balance
  end

  def cleared=(ids)
    @ids_to_clear = ids
    @already_updated = false
  end

  protected

    def initialize_starting_balance
      self.starting_balance ||= account.statements.balanced.last.try(:ending_balance) || 0
    end

    def associate_account_items_with_self
      return if @already_updated
      @already_updated = true

      account_items.clear

      ids = connection.select_values(sanitize_sql([<<-SQL.squish, account_id, ids_to_clear]))
        SELECT ai.id
          FROM account_items ai
         WHERE ai.account_id = ?
           AND ai.id IN (?)
      SQL

      connection.update(sanitize_sql([<<-SQL.squish, id, ids]))
        UPDATE account_items
           SET statement_id = ?
         WHERE id IN (?)
      SQL

      account_items.reset

      if @ids_to_clear
        if balanced?(true) && !balanced_at
          update_attribute :balanced_at, Time.now.utc
        elsif !balanced? && balanced_at
          update_attribute :balanced_at, nil
        end
      end
    end

  private

    def sanitize_sql(sql)
      self.class.send(:sanitize_sql, sql)
    end

    def ids_to_clear
      @ids_to_clear || []
    end

end
