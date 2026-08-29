class AppProxy::ProductsController < AppProxyController
  def index
    filters = params.permit!.to_h
    page = params[:page] || 1
    per_page = params[:per_page] || 12

    products = @shop.products.active

    # Apply filters
    filters.each do |attribute_type, value|
      next if attribute_type.in?(["page", "per_page"])
      products = products.joins(:product_vehicle_attributes)
        .joins(:vehicle_attributes)
        .where(vehicle_attributes: { attribute_type: attribute_type }, product_vehicle_attributes: { value: value })
        .distinct
    end

    total_count = products.count
    products = products.page(page).per(per_page)

    render json: {
      products: products.map { |p| product_json(p) },
      pagination: {
        current_page: page.to_i,
        per_page: per_page.to_i,
        total_count: total_count,
        total_pages: (total_count / per_page.to_i).ceil
      }
    }
  end

  private

  def product_json(product)
    {
      id: product.shopify_product_id,
      title: product.title,
      attributes: product.product_vehicle_attributes.map { |pva| { type: pva.attribute_type, value: pva.value } }
    }
  end
end
