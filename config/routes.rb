Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "products#index"
  resources :products, only: %i[index show]

  resources :orders, only: %i[index show new create] do
    post :pay, on: :member # POST /orders/:id/pay -> Orders::Pay (bước 4)
  end

  # Bước 5: webhook từ cổng thanh toán
  post "webhooks/payments", to: "webhooks#payments"

  # Bước 9: endpoint load test (chỉ để học)
  get "benchmark/io", to: "benchmarks#io"
  get "benchmark/cpu", to: "benchmarks#cpu"
  get "benchmark/db", to: "benchmarks#db"
end
