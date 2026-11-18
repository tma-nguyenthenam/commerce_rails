module ProductsHelper
  # Stores are under storage/products/... ; serve via a controller or
  # through a static path. Simplest: mount storage and build a path.
  def product_image_url(relative_path)
    return "pattern.svg" if relative_path.blank?
    # relative_path examples:
    #   "products/12/my-slug_thumbnail.jpg"
    #   "products/12/my-slug_index_slide_0.png"
    "/storage/#{relative_path}"
  end
end
