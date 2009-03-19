class AccountsController < ApplicationController
  before_filter :find_account, :except => :create
  before_filter :find_subscription, :only => :create

  def show
    @page = (params[:page] || 0).to_i
    @more_pages, @items = account.account_items.page(@page)
  end

  def create
    @account = subscription.accounts.create(params[:account].merge(:author => user))
  end

  protected

    attr_reader :account
    helper_method :account

    def find_account
      @account = Account.find(params[:id])
      @subscription = user.subscriptions.find(@account.subscription_id)
    end

    def find_subscription
      @subscription = user.subscriptions.find(params[:subscription_id])
    end

    def current_location
      if account
        "accounts/%d" % account.id
      else
        super
      end
    end
end
