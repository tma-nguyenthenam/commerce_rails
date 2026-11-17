class StoreController < ApplicationController
  layout "store", :only => [ :index, :show ]
  before_action :load_categories, only: %i[index show]

  def index
    @products = Catalog::ProductsList.call
  end

  def show
    
  end

  private

  def load_categories
    @categories = Category.order(:name)
  end
end