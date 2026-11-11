class ProductsController < ApplicationController
  def index
    # Bước 7: danh sách đi qua cache (xem Catalog::ProductsList để hiểu chiến lược).
    @products = Catalog::ProductsList.call
  end

  def show
    @product = Product.find(params[:id])
  end
end
