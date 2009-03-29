# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all

  protect_from_forgery

  before_filter :authenticate

  rescue_from ActiveRecord::RecordNotFound, :with => :render_404

  protected

    attr_reader :subscription, :user
    helper_method :subscription, :user

    def authenticate
      if session[:user_id]
        @user = User.find(session[:user_id])
      else
        redirect_to(new_session_url)
      end
    end

    def find_subscription
      @subscription = Subscription.find(1)
    end

    def current_location
      controller_name
    end
    helper_method :current_location

    def render_404
      render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found
    end
end
