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
      attach_uploads(@product)
      if @product.save
        redirect_to @product, notice: "Product created."
      else
        render :new, status: :unprocessable_entity
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @categories = Category.all
    @product.assign_attributes(product_params)

    if @product.update(product_params)
      attach_uploads(@product)
      if @product.save
        redirect_to @product, notice: "Product updated."
      else
        render :edit, status: :unprocessable_entity
      end
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
    params.require(:product).permit(
      :name, :description, :price, :stock, :category_id,
      :tagline, :is_new, :slug,
      colors: [],              # array of strings
      options: {},             # jsonb
      images: []               # images array
    )
  end

  def attach_uploads(product)
    base_dir = Rails.root.join("storage", "products", product.id.to_s, product.slug)
    FileUtils.mkdir_p(base_dir)

    # --- Thumbnail ---
    thumb_upload = params.dig(:product, :thumbnail_upload)
    if thumb_upload.respond_to?(:original_filename) && thumb_upload.size.positive?
      ext = File.extname(thumb_upload.original_filename)
      filename = "#{product.slug}_thumbnail#{ext}"
      save_file(thumb_upload, base_dir.join(filename))
      product.thumbnail = "products/#{product.id}/#{product.slug}/#{filename}"
    end

    # --- Gallery images ---
    gallery_uploads = Array(params.dig(:product, :image_uploads)).reject(&:blank?)
    if gallery_uploads.any?
      existing = Array(product.images).dup
      gallery_uploads.each_with_index do |upload, index|
        ext = File.extname(upload.original_filename)
        filename = "#{product.slug}_index_slide_#{index}#{ext}"
        save_file(upload, base_dir.join(filename))
        rel = "products/#{product.id}/#{product.slug}/#{filename}"
        existing << rel unless existing.include?(rel)
      end
      product.images = existing
    end
  end

  def save_file(upload, dest)
    File.open(dest, "wb") { |f| f.write(upload.read) }
  end
end
