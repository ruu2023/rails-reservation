Rails.application.routes.draw do
  get "sessions/new"
  get "sessions/create"
  get "sessions/destroy"
  get "up" => "rails/health#show", as: :rails_health_check
  root "sessions#new" # ログイン画面

  # OmniAuth専用のルート
  get "/auth/:provider/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  resources :events
end
