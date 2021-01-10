class ApplicationController < ActionController::Base
  before_action :authenticate

  attr_reader :subscription, :user
  helper_method :subscription, :user

  def current_location
    controller_name
  end
  helper_method :current_location

  def authenticate
    if session[:user_id]
      @user = User.find(session[:user_id])
    # elsif via_api?
    #   authenticate_or_request_with_http_basic do |user_name, password|
    #     @user = User.authenticate(user_name, password)
    #   end
    else
      redirect_to(new_session_url)
    end
  end

  def find_subscription
    @subscription = user.subscriptions.find(params[:subscription_id] || params[:id])
  end

  def via_api?
    request.format == Mime::XML
  end
end
