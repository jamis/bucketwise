class SubscriptionsController < ApplicationController
  before_filter :find_subscription, :except => :index

  def index
  end

  def show
  end

  protected

    def find_subscription
      @subscription = user.subscriptions.find(params[:id])
    end
end
