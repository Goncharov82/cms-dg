Rails.application.routes.draw do
  root "home#index"

  get "login", to: "sessions#new", as: :login
  resource :session, only: %i[create destroy]

  namespace :admin do
    root "dashboard#index"
    resources :articles
    resources :categories, only: %i[index new create]
    resources :pages, only: %i[index new create]
    resource :site_menu, only: :show, controller: "site_menu"
    resources :menu_items, only: %i[new create], path: "site_menu/items", controller: "menu_items"
    resource :analytics, only: :show
  end

  namespace :api do
    namespace :v1 do
    end
  end

  namespace :webhooks do
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
