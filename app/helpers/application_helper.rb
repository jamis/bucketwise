# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def visible?(flag)
    if flag
      nil
    else
      "display: none"
    end
  end
end
