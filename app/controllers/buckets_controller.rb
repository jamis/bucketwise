class BucketsController < ApplicationController
  # acceptable_includes :author

  before_action :find_account, :only => %w(index new create)
  before_action :find_bucket, :except => %w(index new create)

  def index
    @filter = QueryFilter.new(params)
    @buckets = account.buckets.apply_filter(@filter)

    respond_to do |format|
      format.html
      format.xml { render :xml => @buckets.to_xml(eager_options(:root => "buckets")) }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @page = (params[:page] || 0).to_i
        @more_pages, @items = bucket.line_items.page(@page)
      end

      format.xml { render :xml => bucket.to_xml(eager_options) }
    end
  end

  def new
    respond_to { |format| format.xml { render :xml => Bucket.template.to_xml } }
  end

  def create
    respond_to do |format|
      format.xml do
        @bucket = account.buckets.create!(params[:bucket], :author => user)
        render :status => :created, :xml => @bucket.to_xml, :location => bucket_url(@bucket)
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    @bucket = error.record
    respond_to do |format|
      format.xml { render :status => :unprocessable_entity, :xml => @bucket.errors.to_xml }
    end
  end

  def update
    bucket.update_attributes!(params[:bucket])

    respond_to do |format|
      format.js
      format.xml { render :xml => bucket.to_xml }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.js
      format.xml { render :status => :unprocessable_entity, :xml => bucket.errors.to_xml }
    end
  end

  def destroy
    receiver = account.buckets.find(params[:receiver_id])
    receiver.assimilate(bucket)

    respond_to do |format|
      format.html { redirect_to(receiver) }
      format.xml  { head :ok }
    end
  end

  protected

    attr_reader :account, :bucket, :buckets, :filter
    helper_method :account, :bucket, :buckets, :filter

    def find_account
      @account = Account.find(params[:account_id])
      @subscription = user.subscriptions.find(@account.subscription_id)
    end

    def find_bucket
      @bucket = Bucket.find(params[:id])
      @account = @bucket.account
      @subscription = user.subscriptions.find(@account.subscription_id)
    end

    def current_location
      if bucket
        "buckets/%d" % bucket.id
      else
        super
      end
    end
end
