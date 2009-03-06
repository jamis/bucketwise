ActionController::Routing::Routes.draw do |map|
  map.resource :dashboard
  map.resources :events, :buckets, :accounts
end
