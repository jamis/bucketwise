class TaggedItemsController < ApplicationController
  before_action :find_event, :only => :create
  before_action :find_tagged_item, :only => :destroy

  def create
    @tagged_item = event.tagged_items.create!(params[:tagged_item])
    respond_to do |format|
      format.xml do
        render :status => :created, :location => tagged_item_url(@tagged_item),
          :xml => @tagged_item
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.xml { render :status => :unprocessable_entity, :xml => error.record.errors }
    end
  end

  def destroy
    tagged_item.destroy
    respond_to { |format| format.xml { head :ok } }
  end

  protected

    attr_reader :event, :tagged_item
    helper_method :event, :tagged_item

    def find_event
      @event = Event.find(params[:event_id])
      @subscription = user.subscriptions.find(@event.subscription_id)
    end

    def find_tagged_item
      @tagged_item = TaggedItem.find(params[:id])
      @event = @tagged_item.event
      @subscription = user.subscriptions.find(@event.subscription_id)
    end
end
