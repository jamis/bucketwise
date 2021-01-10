ENV['RAILS_ENV'] ||= 'test'
require_relative "../config/environment"
require "rails/test_help"

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

    def api_login!(who, password)
      logout!
      @user = Symbol === who ? users(who) : who
      token = Base64.encode64("#{@user.user_name}:#{password}")
      @request.env['HTTP_AUTHORIZATION'] = "Basic: #{token}"
    end
end
