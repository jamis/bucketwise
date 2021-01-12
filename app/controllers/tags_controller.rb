class TagsController < ApplicationController
  before_action :find_subscription, :only => %w(index new create)
  before_action :find_tag, :except => %w(index new create)

  def index
    respond_to do |format|
      format.xml { render :xml => subscription.tags.to_xml(:root => "tags") }
    end
  end

  def show
    respond_to do |format|
      format.html do
        @page = (params[:page] || 0).to_i
        @more_pages, @items = tag_ref.tagged_items.page(@page)
      end
      format.xml { render :xml => tag_ref }
    end
  end

  def new
    respond_to { |format| format.xml { render :xml => Tag.template } }
  end

  def create
    respond_to do |format|
      format.xml do
        @tag_ref = subscription.tags.create!(tags_params)
        render :xml => @tag_ref, :status => :created, :location => tag_url(@tag_ref)
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    respond_to do |format|
      format.xml { render :status => :unprocessable_entity, :xml => error.record.errors }
    end
  end

  def update
    tag_ref.update!(tags_params)
    respond_to do |format|
      format.js
      format.xml { render :xml => tag_ref }
    end
  rescue ActiveRecord::RecordInvalid
    respond_to do |format|
      format.js
      format.xml { render :status => :unprocessable_entity, :xml => tag_ref.errors }
    end
  end

  def destroy
    if params[:receiver_id].present?
      receiver = subscription.tags.find(params[:receiver_id])
      receiver.assimilate(tag_ref)
    else
      tag_ref.destroy
    end

    respond_to do |format|
      format.html { redirect_to(receiver || subscription) }
      format.xml { head :ok }
    end
  rescue ActiveRecord::RecordNotSaved => error
    head :unprocessable_entity
  end

  protected

  # can't call it 'tag' because that conflicts with the Rails 'tag()'
  # helper method. 'tag_ref' is lame, but sufficient.
  attr_reader :tag_ref
  helper_method :tag_ref

  def find_tag
    @tag_ref = Tag.find(params[:id])
    @subscription = user.subscriptions.find(@tag_ref.subscription_id)
  end

  def current_location
    if tag_ref
      "tags/%d" % tag_ref.id
    else
      super
    end
  end

  def tags_params
    params.require(:tag).permit(:name, :balance)
  end
end
