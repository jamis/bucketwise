ActionController::Routing::Routes.draw do |map|
  map.resource :session

  map.resources :subscriptions
  map.resources :events, :member => { :update => :post }
  map.resources :buckets
  map.resources :accounts, :has_many => :buckets
end
