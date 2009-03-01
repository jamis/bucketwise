class EventsController < ApplicationController
  def create
    @event = Event.create(params[:event])
  end
end
