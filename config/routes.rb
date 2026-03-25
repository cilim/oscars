Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]

  resources :seasons, only: [ :index, :show ] do
    resource :picks, only: [ :edit, :update ]
    resource :scoreboard, only: [ :show ]
  end

  namespace :admin do
    get  "tmdb_search", to: "tmdb_search#search"
    post "import/:year", to: "imports#create", as: :import
    resource :database_backup, only: [ :show ] do
      post :import, on: :collection
    end
    resources :scrapes, only: [ :new, :create ] do
      post :import, on: :collection
    end
    resources :seasons do
      resources :season_categories, only: [ :create, :destroy ] do
        resources :nominees, except: [ :index, :show ]
      end
      resources :players, only: [ :create, :destroy ]
      resources :winners, only: [ :create, :destroy ]
    end
    resources :categories
    resources :users
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "seasons#index"
end
