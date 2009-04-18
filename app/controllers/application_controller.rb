# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include OptionHandler

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

    def current_location
      controller_name
    end
    helper_method :current_location

    def render_404
      respond_to do |format|
        format.html { render :file => "#{RAILS_ROOT}/public/404.html", :status => :not_found }
        format.xml  { head :missing }
      end
    end

  private

    def self.acceptable_includes(*list)
      includes = read_inheritable_attribute(:accessible_includes) || []

      if list.any?
        includes = Set.new(list.map(&:to_s)) + includes
        write_inheritable_attribute(:accessible_includes, includes)
      end

      includes
    end

    def acceptable_includes
      self.class.acceptable_includes
    end

    def eager_options(options={})
      if params[:include]
        list = acceptable_includes & params[:include].split(/,/)
        append_to_options(options, :include, list.map(&:to_sym)) if list.any?
      end

      return options
    end
end
