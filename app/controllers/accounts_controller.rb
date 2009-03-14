class AccountsController < ApplicationController
  def create
    @account = subscription.accounts.create(params[:account].merge(:author => user))
  end
end
