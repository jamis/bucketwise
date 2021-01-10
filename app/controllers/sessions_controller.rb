class SessionsController < ApplicationController
  skip_before_action :authenticate

  layout nil

  def new
  end

  def create
    @user = User.authenticate(params[:user_name], params[:password])

    if @user.nil?
      flash[:failed] = true
      redirect_to(new_session_url)
    else
      session[:user_id] = @user.id

      if @user.subscriptions.length > 1
        redirect_to(subscriptions_url)
      else
        redirect_to(subscription_url(@user.subscriptions.first))
      end
    end
  end

  def destroy
    flash[:logged_out] = true
    session[:user_id] = nil
    redirect_to(new_session_url)
  end
end
