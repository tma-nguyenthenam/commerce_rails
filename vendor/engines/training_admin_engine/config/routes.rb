TrainingAdminEngine::Engine.routes.draw do
  root "dashboard#index"

  namespace :api do
    namespace :v1 do
      get 'dashboard/stats', to: 'dashboard#stats'
      get 'dashboard/orders', to: 'dashboard#orders'
    end
  end
end