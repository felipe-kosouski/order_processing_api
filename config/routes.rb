require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"
  get "up" => "rails/health#show", as: :rails_health_check

  resources :orders, only: %i[index] do
    post "upload", on: :collection
  end
end
