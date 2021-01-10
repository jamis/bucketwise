Rails.application.routes.draw do
  resource :session

  resources :subscriptions do
    resources :events, :member => { :update => :post }, shallow: true do
      resources :tagged_items
    end
    resources :accounts, shallow: true do #, :has_many => [:buckets, :events, :statements]
      resources :buckets, :has_many => :events
      resources :statements
    end
    resources :tags, :has_many => :events
  end



  root to: 'subscriptions#index'
  # map.with_options :controller => "subscriptions", :action => "index" do |home|
  #   home.root
  #   home.connect ""
  # end
end
