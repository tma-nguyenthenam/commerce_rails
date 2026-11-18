Rails.application.routes.draw do
  mount TrainingAdminEngine::Engine => "/admin"
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication
  get "/auth/:provider/callback", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  root "store#index"
  resources :products
  resources :categories, only: [:create]

  resources :orders, only: %i[index show new create] do
    post :pay, on: :member # POST /orders/:id/pay -> Orders::Pay (bước 4)
  end

  # Bước 5: webhook từ cổng thanh toán
  post "webhooks/payments", to: "webhooks#payments"

  # Bước 9: endpoint load test (chỉ để học)
  get "benchmark/io", to: "benchmarks#io"
  get "benchmark/cpu", to: "benchmarks#cpu"
  get "benchmark/db", to: "benchmarks#db"

  get "/buy/:product_id", to: "store#show", as: :show_products,
  constraints: { product_id: /[a-z0-9\-]+/ }

  get "/:category_id", to: "categories#index", as: :category_products,
  constraints: { category_id: /[a-z0-9\-]+/ }
  get "/storage/*path", to: "storage#show", format: false
end
