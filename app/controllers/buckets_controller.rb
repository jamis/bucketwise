class BucketsController < ApplicationController
  before_filter :find_account, :only => :index

  def index
  end

  protected

    attr_reader :account
    helper_method :account

    def find_account
      @account = subscription.accounts.find(params[:account_id])
    end
end
