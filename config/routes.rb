ActionController::Routing::Routes.draw do |map|
  map.resource :dashboard
  map.resources :events, :member => { :update => :post }
  map.resources :buckets
  map.resources :accounts, :has_many => :buckets
end
