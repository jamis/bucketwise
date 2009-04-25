ActionController::Routing::Routes.draw do |map|
  map.resource :session

  map.resources :subscriptions, :has_many => [:accounts, :events, :tags]
  map.resources :events, :has_many => :tagged_items, :member => { :update => :post }
  map.resources :buckets, :has_many => :events
  map.resources :accounts, :has_many => [:buckets, :events, :statements]
  map.resources :tags, :has_many => :events
  map.resources :tagged_items, :statements

  map.connect "", :controller => "subscriptions", :action => "index"
end
