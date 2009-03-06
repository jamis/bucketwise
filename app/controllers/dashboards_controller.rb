class DashboardsController < ApplicationController
  def show
    @subscription = Subscription.find(:first)
  end
end
