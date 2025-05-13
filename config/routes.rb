require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users
  mount Sidekiq::Web => '/sidekiq'
  resource :cart, only: %i[show create] do
    post 'add_item'
  end
  resources :products
  get "up" => "rails/health#show", as: :rails_health_check

  root "rails/health#show"
end
