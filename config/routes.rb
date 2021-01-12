Rails.application.routes.draw do
  resource :session do
    get :logout, on: :member
  end

  resources :events do
    get :show, on: :member
    post :update, on: :member
  end

  resources :subscriptions do
    resources :events, shallow: true do
      resources :tagged_items
    end
    resources :accounts, shallow: true do
      resources :buckets, shallow: true do
        resources :events
      end
      resources :events
      resources :statements
    end
    resources :tags, shallow: true do
      resources :events
    end
  end



  root to: 'subscriptions#index'
  # map.with_options :controller => "subscriptions", :action => "index" do |home|
  #   home.root
  #   home.connect ""
  # end
end
