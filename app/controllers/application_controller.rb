# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '6acd7a19e14fbc4cc26255206125631f'

  before_filter :authenticate

  protected

    attr_reader :subscription, :user
    helper_method :subscription, :user

    def authenticate
      if session[:user_id]
        @user = User.find(session[:user_id])
      else
        redirect_to(session_url)
      end
    end

    def find_subscription
      @subscription = Subscription.find(1)
    end

    def current_location
      controller_name
    end
    helper_method :current_location
end
