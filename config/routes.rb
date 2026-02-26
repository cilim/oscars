Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]

  resources :seasons, only: [ :index, :show ] do
    resource :picks, only: [ :edit, :update ]
    resource :scoreboard, only: [ :show ]
  end

  namespace :admin do
    resources :seasons do
      resources :season_categories, only: [ :create, :destroy ] do
        resources :nominees, except: [ :index, :show ]
      end
      resources :players, only: [ :create, :destroy ]
      resources :winners, only: [ :create, :destroy ]
    end
    resources :categories
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "seasons#index"
end
