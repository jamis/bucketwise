module CategorizedItems
  def deposits
    @deposits ||= to_a.select { |item| item.amount > 0 }
  end

  def checks
    @checks ||= to_a.select { |item| item.amount < 0 && item.event.check_number.present? }
  end

  def expenses
    @expenses ||= to_a.select { |item| item.amount < 0 && item.event.check_number.blank? }
  end
end
