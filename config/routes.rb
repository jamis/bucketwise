Rails.application.routes.draw do
  resource :session

  resources :subscriptions, :has_many => [:accounts, :events, :tags] do
    resources :events, :has_many => :tagged_items, :member => { :update => :post }
    resources :accounts, :has_many => [:buckets, :events, :statements]
  end

  resources :buckets, :has_many => :events
  resources :tags, :has_many => :events
  resources :tagged_items, :statements

  root to: 'subscriptions#index'
  # map.with_options :controller => "subscriptions", :action => "index" do |home|
  #   home.root
  #   home.connect ""
  # end
end
