require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resource :cart, only: %i[show] do
    post 'add_item'
  end
  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
