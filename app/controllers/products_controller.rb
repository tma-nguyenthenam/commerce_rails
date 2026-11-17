class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]
  before_action :load_categories, only: %i[new create edit update]

  def index
    # Bước 7: danh sách đi qua cache (xem Catalog::ProductsList để hiểu chiến lược).
    @products = Catalog::ProductsList.call
  end

  def show
    @product = Product.find(params[:id])
  end

  def new
    @product = Product.new
    @categories = Category.all
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product was deleted."
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def load_categories
    @categories = Category.order(:name)
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :category_id)
  end
end
