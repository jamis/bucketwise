class EventsController < ApplicationController
  before_filter :find_event, :except => %w(create)

  def show
  end

  def create
    @event = subscription.events.create(params[:event].merge(:user_id => user.id))
  end

  def destroy
    event.destroy
  end

  protected

    attr_reader :event
    helper_method :event

    def find_event
      @event = subscription.events.find(params[:id])
    end
end
