# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def visible?(flag)
    if flag
      nil
    else
      "display: none"
    end
  end

  def application_revision
    @application_revision ||= if File.exists?("#{RAILS_ROOT}/REVISION")
      File.read("#{RAILS_ROOT}/REVISION").strip
    else
      "HEAD"
    end
  end

  def application_last_deployed
    if File.exists?("#{RAILS_ROOT}/REVISION")
      @deployed_at ||= File.stat("#{RAILS_ROOT}/REVISION").ctime
      time_ago_in_words(@deployed_at) + " ago"
    else
      "(not deployed)"
    end
  end

  def format_cents(amount, options={})
    number_to_currency(amount/100.0, options)
  end
end
