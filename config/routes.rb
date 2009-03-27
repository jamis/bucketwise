ActionController::Routing::Routes.draw do |map|
  map.resource :session

  map.resources :subscriptions, :has_many => [:accounts, :events, :tags]
  map.resources :events, :member => { :update => :post }
  map.resources :buckets
  map.resources :accounts, :has_many => :buckets
  map.resources :tags

  map.connect "", :controller => "subscriptions", :action => "index"
end
