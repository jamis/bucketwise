ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class ActiveSupport::TestCase
  fixtures :all

  protected

    def login_default_user
      login! :john
    end

  private

    def login!(who)
      @user = Symbol === who ? users(who) : who
      @request.session[:user_id] = @user.id
    end

    def logout!
      @request.session[:user_id] = nil
    end
end
