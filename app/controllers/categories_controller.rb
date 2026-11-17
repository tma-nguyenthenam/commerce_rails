class CategoriesController < ApplicationController  
  layout "store", :only => [ :index ]
  skip_forgery_protection only: :create  # or keep CSRF (recommended) - see note below

  def index
    @products = Product.includes(:category).order(created_at: :desc)
    @categories = Category.order(:name)
  
    if params[:category_id].present?
      @current_category =
        if params[:category_id].to_s.match?(/\A\d+\z/)
          Category.find(params[:category_id])
        else
          Category.find_by!(slug: params[:category_id])
        end
      @products = @products.where(category_id: @current_category.id)
    end
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      render json: { id: @category.id, name: @category.name }, status: :created
    else
      render json: { errors: @category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def category_params
    params.require(:category).permit(:name, :description)
  end
end
