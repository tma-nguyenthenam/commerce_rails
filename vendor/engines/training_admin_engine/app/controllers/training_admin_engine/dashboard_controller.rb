module TrainingAdminEngine
  class DashboardController < ApplicationController
    def index
    end

    def orders
      @orders = Order.includes(:user).order(id: :desc)
    end

    def products
    end
  end
end
