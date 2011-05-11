require File.dirname(__FILE__) + '/config/environment'

if Rails.env.development?
  use Rails::Rack::Static
end

run ActionController::Dispatcher.new
