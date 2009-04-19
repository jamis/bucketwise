# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def visible?(flag)
    if flag
      nil
    else
      "display: none"
    end
  end

  def application_version
    @application_version ||= if File.exists?("#{RAILS_ROOT}/REVISION")
      File.read("#{RAILS_ROOT}/REVISION").strip
    else
      "(development)"
    end
  end

  def application_last_deployed
    @application_last_deployed ||= if File.exists?("#{RAILS_ROOT}/REVISION")
      deployed_at = File.stat("#{RAILS_ROOT}/REVISION").ctime
      time_ago_in_words(deployed_at) + " ago"
    else
      "(not deployed)"
    end
  end
end
