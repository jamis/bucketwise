ActionController::Routing::Routes.draw do |map|
  map.resource :dashboard
  map.resources :events, :buckets
  map.resources :accounts, :has_many => :buckets
end
