class QueryFilter
  attr_reader :from
  attr_reader :to

  def initialize(options={})
    @has_from = @has_to = false

    begin
      @from = Date.parse(options[:from])
      @has_from = true
    rescue
      @from = 3.months.ago.to_date
    end

    begin
      @to = Date.parse(options[:to])
      @has_to = true
    rescue
      @to = Date.today
    end

    @expenses = options[:expenses]
    @deposits = options[:deposits]
    @reallocations = options[:reallocations]

    if !@expenses && !@deposits && !@reallocations
      @expenses = @deposits = @reallocations = true
    end
  end

  def by_date?
    from? || to?
  end

  def from?
    @has_from
  end

  def to?
    @has_to
  end

  def by_type?
    !expenses? || !deposits? || !reallocations?
  end

  def expenses?
    @expenses
  end

  def deposits?
    @deposits
  end

  def reallocations?
    @reallocations
  end

  def any?
    by_date? || by_type?
  end

  def to_s
    description = "Filter"

    if any?
      description << ": "

      parts = [
        expenses? && "expenses",
        deposits? && "deposits", 
        reallocations? && "reallocations"
      ].compact

      if parts.length == 3
        description << "all transactions"
      else
        description << parts.to_sentence
      end

      description << " from " << from.strftime("%Y-%m-%d") if from?
      description << " to " << to.strftime("%Y-%m-%d") if to?
    end

    return description
  end
end
