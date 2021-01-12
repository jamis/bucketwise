class ApplicationController < ActionController::Base
  include OptionHandler

  before_action :authenticate

  attr_reader :subscription, :user
  helper_method :subscription, :user

  rescue_from ActiveRecord::RecordNotFound, :with => :render_404

  class_attribute :acceptable_includes, default: []

  def current_location
    controller_name
  end
  helper_method :current_location

  def authenticate
    if session[:user_id]
      @user = User.find(session[:user_id])
    elsif via_api?
      authenticate_or_request_with_http_basic do |user_name, password|
        @user = User.authenticate(user_name, password)
      end
    else
      redirect_to(new_session_url)
    end
  end

  def find_subscription
    @subscription = user.subscriptions.find(params[:subscription_id] || params[:id])
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root.join('public', '404.html')}", :status => :not_found, layout: false }
      format.xml  { head :not_found }
    end
  end

  def via_api?
    request.format == Mime[:xml]
  end

  private

  def eager_options(options={})
    if params[:include]
      list = acceptable_includes & params[:include].split(/,/).map(&:to_sym)
      append_to_options(options, :include, list) if list.any?
    end

    options
  end
end
