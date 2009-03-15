class BucketsController < ApplicationController
  before_filter :find_account, :only => :index
  before_filter :find_bucket, :only => :show

  def index
  end

  def show
    @page = (params[:page] || 0).to_i
    @more_pages, @items = bucket.line_items.page(@page)
  end

  protected

    attr_reader :account, :bucket
    helper_method :account, :bucket

    def find_account
      @account = subscription.accounts.find(params[:account_id])
    end

    def find_bucket
      @bucket = Bucket.find(params[:id])
      @account = subscription.accounts.find(@bucket.account_id)
    end
end
