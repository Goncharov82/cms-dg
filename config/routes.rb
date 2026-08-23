Rails.application.routes.draw do
  root "home#index"

  get "login", to: "sessions#new", as: :login
  resource :session, only: %i[create destroy]

  namespace :admin do
    root "dashboard#index"
    resources :articles, except: :show do
      patch :toggle_status, on: :member
    end
    resources :categories, only: %i[index new create edit update] do
      patch :toggle_status, on: :member
    end
    resources :pages, only: %i[index new create edit update] do
      patch :toggle_status, on: :member
    end
    resource :site_menu, only: :show, controller: "site_menu"
    resources :menu_items, only: %i[new create edit update], path: "site_menu/items", controller: "menu_items" do
      patch :toggle_status, on: :member
    end
    resource :analytics, only: :show
    resource :settings, only: %i[show update]
    post "settings/check_updates", to: "settings#check_updates", as: :settings_check_updates
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

  get "images/blog/*filename", to: "media#blog", as: :blog_image, format: false
  get "media/:id/:filename", to: "media#show", as: :legacy_media_asset, format: false
  get "authors/:id/avatar", to: "media#author_avatar", as: :author_avatar, format: false

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "*legacy_path", to: "legacy_content#show", format: false
end
