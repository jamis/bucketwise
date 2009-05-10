class EventsController < ApplicationController
  acceptable_includes :line_items, :user, :tagged_items

  before_filter :find_container, :find_events, :only => :index
  before_filter :find_subscription, :only => %w(new create)
  before_filter :find_event, :except => %w(index new create)

  def index
    respond_to do |format|
      format.js do
        json = events.to_json(eager_options(:root => "events", :include => { :tagged_items => { :only => [:amount, :id], :methods => :name }, :line_items => { :only => [:account_id, :bucket_id, :amount, :role], :methods => [] }}))

        render :update do |page|
          page << "Events.doneLoadingRecalledEvents(#{json})"
        end
      end
      format.xml do
        render :xml => events.to_xml(eager_options(:root => "events"))
      end
    end
  end

  def show
    respond_to do |format|
      format.js
      format.xml { render :xml => event.to_xml(eager_options) }
    end
  end

  def edit
  end

  def new
    @event = subscription.events.prepare(params)

    respond_to do |format|
      format.html
      format.xml { render :xml => event.to_xml(:include => [:line_items, :tagged_items]) }
    end
  end

  def create
    @event = subscription.events.create!(params[:event], :user => user)
    respond_to do |format|
      format.js
      format.xml do
        render :status => :created, :location => event_url(@event),
          :xml => @event.to_xml(:include => [:line_items, :tagged_items])
      end
    end
  rescue ActiveRecord::RecordInvalid => error 
    @event = error.record
    respond_to do |format|
      format.js
      format.xml { render :status => :unprocessable_entity, :xml => @event.errors }
    end
  end

  def update
    event.update_attributes!(params[:event])
    respond_to do |format|
      format.js
      format.xml { render :xml => event.to_xml(:include => [:line_items, :tagged_items]) }
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.js
      format.xml { render :status => :unprocessable_entity, :xml => event.errors }
    end
  end

  def destroy
    event.destroy
    respond_to do |format|
      format.js
      format.xml { head :ok }
    end
  end

  protected

    attr_reader :event, :container, :account, :bucket, :tag, :events
    helper_method :event, :container, :account, :bucket

    def find_event
      @event = Event.find(params[:id])
      @subscription = user.subscriptions.find(@event.subscription_id)
    end

    def find_container
      if params[:subscription_id]
        @container = find_subscription
      elsif params[:account_id]
        @container = @account = Account.find(params[:account_id])
        @subscription = user.subscriptions.find(@account.subscription_id)
      elsif params[:bucket_id]
        @container = @bucket = Bucket.find(params[:bucket_id])
        @subscription = user.subscriptions.find(@bucket.account.subscription_id)
      elsif params[:tag_id]
        @container = @tag = Tag.find(params[:tag_id])
        @subscription = user.subscriptions.find(@tag.subscription_id)
      else
        raise ArgumentError, "no container specified for event listing"
      end
    end

    def find_events
      method = :page

      case container
      when Subscription then
        association = :events
        method = :recent
      when Account
        association = :account_items
      when Bucket
        association = :line_items
      when Tag
        association = :tagged_items
      else
        raise ArgumentError, "unsupported container type #{container.class}"
      end

      more_pages, list = container.send(association).send(method, params[:page], :size => params[:size], :actor => params[:actor])
      unless list.first.is_a?(Event)
        list = list.map do |item| 
          event = item.event
          event.amount = item.amount
          event
        end
      end

      @events = list
    end
end
