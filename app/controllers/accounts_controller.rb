class AccountsController < ApplicationController
  before_filter :find_account, :except => :create

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
      @account = subscription.accounts.find(params[:id])
    end

    def current_location
      if account
        "accounts/%d" % account.id
      else
        super
      end
    end
end
