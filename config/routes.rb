ActionController::Routing::Routes.draw do |map|
  map.resource :session

  map.resources :subscriptions, :has_many => [:accounts, :events, :tags]
  map.resources :events, :member => { :update => :post }
  map.resources :buckets, :has_many => :events
  map.resources :accounts, :has_many => [:buckets, :events]
  map.resources :tags, :has_many => :events

  map.connect "", :controller => "subscriptions", :action => "index"
end
