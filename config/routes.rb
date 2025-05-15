require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  resource :cart, only: %i[show create] do
    post 'add_item'
    delete ':product_id', to: 'carts#destroy'
  end
  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
