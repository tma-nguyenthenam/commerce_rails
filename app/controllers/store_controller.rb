class StoreController < ApplicationController
  layout "store", :only => [ :index, :show ]
  before_action :load_categories, only: %i[index show]

  def index
    @products = Product.order(:created_at)
  end

  def show
    @idempotency_key = SecureRandom.uuid
    @product = if params[:product_id].to_s.match?(/\A\d+\z/)
      Product.find(params[:product_id])
    else
      Product.find_by!(slug: params[:product_id])
    end
  end

  private

  def load_categories
    @categories = Category.order(:name)
  end
end