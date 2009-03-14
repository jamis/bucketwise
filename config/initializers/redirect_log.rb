# For use from the console, so you can view the log output without
# having to tail a log in a separate terminal window.
def redirect_log(options={})
  ActiveRecord::Base.logger = Logger.new(options.fetch(:to, STDERR))
  ActiveRecord::Base.clear_active_connections!
  ActiveRecord::Base.colorize_logging = options.fetch(:colorize, true)
end
