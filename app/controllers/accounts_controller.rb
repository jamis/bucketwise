class AccountsController < ApplicationController
  # acceptable_includes :author, :buckets

  before_action :find_account, :except => %w(index create new)
  before_action :find_subscription, :only => %w(index create new)

  def index
    respond_to do |format|
      format.xml { render :xml => subscription.accounts.to_xml(eager_options(:root => "accounts")) }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @page = (params[:page] || 0).to_i
        @more_pages, @items = account.account_items.page(@page)
      end

      format.xml { render :xml => account.to_xml(eager_options) }
    end
  end

  def new
    respond_to do |format|
      format.html
      format.xml { render :xml => Account.template.to_xml }
    end
  end

  def create
    @account = subscription.accounts.where(author: user).create!(account_params)
    respond_to do |format|
      format.html { redirect_to(subscription_url(subscription)) }
      format.xml  { render :xml => @account.to_xml, :status => :created, :location => account_url(@account) }
    end
  rescue ActiveRecord::RecordInvalid => error
    @account = error.record
    respond_to do |format|
      format.html { render :action => "new" }
      format.xml  { render :status => :unprocessable_entity, :xml => @account.errors.to_xml }
    end
  end

  def destroy
    account.destroy
    respond_to do |format|
      format.html { redirect_to(subscription_url(subscription)) }
      format.xml  { head :ok }
    end
  end

  def update
    account.update_attributes!(params[:account])

    respond_to do |format|
      format.js
      format.xml { render :xml => account.to_xml }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.js
      format.xml { render :status => :unprocessable_entity, :xml => account.errors.to_xml }
    end
  end

  protected

  attr_reader :account
  helper_method :account

  def find_account
    @account = Account.find(params[:id])
    @subscription = user.subscriptions.find(@account.subscription_id)
  end

  def current_location
    if account
      "accounts/%d" % account.id
    else
      super
    end
  end

  def account_params
    params.require(:account)
          .permit(:name, :role, :limit, :current_balance, :subscription_id,
                  starting_balance: [ :amount, :occurred_on ] )
  end
end
