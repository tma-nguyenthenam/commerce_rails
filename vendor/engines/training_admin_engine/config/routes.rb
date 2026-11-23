TrainingAdminEngine::Engine.routes.draw do
  root "dashboard#index"
  get 'orders', to: 'dashboard#orders'
  get 'products', to: 'dashboard#products'

  namespace :api do
    namespace :v1 do
      get 'dashboard_api/stats', to: 'dashboard_api#stats'
      get 'dashboard_api/orders', to: 'dashboard_api#orders'
      get 'dashboard_api/total_orders_by_month', to: 'dashboard_api#total_orders_by_month'
      get 'dashboard_api/products', to: 'dashboard_api#products'
    end
  end
end