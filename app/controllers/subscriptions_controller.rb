class SubscriptionsController < ApplicationController
  before_filter :find_subscription, :except => :index

  def index
    if user.subscriptions.length == 1
      redirect_to(subscription_url(user.subscriptions.first))
      return
    end
  end

  def show
  end
end
