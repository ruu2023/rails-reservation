Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  resources :schedules
  root "schedules#index"
end
