module StatementsHelper
  def uncleared_row_class(item)
    classes = [cycle('odd', 'even')]
    classes << "cleared" if item.statement_id
    classes.join(" ")
  end
end
