class AppProxy::FiltersController < AppProxyController
  def index
    # Get all available filter options
    filters = @shop.vehicle_attributes.active.includes(:vehicle_attribute_values).map do |attr|
      {
        name: attr.attribute_type,
        label: attr.label,
        values: attr.vehicle_attribute_values.active.map { |v| { value: v.value, label: v.display_name } }
      }
    end

    render json: { filters: filters }
  end

  def options
    attribute_type = params[:attribute_type]
    
    attribute = @shop.vehicle_attributes.by_type(attribute_type).first
    return render json: { error: "Attribute not found" }, status: :not_found unless attribute

    options = attribute.vehicle_attribute_values.active.order(:sort_order, :value).map do |v|
      { value: v.value, label: v.display_name }
    end

    render json: { options: options }
  end

  def search
    filters = params.require(:filters).permit!.to_h
    
    # Find products matching all filters
    products = @shop.products.active
    
    filters.each do |attribute_type, value|
      products = products.joins(:product_vehicle_attributes)
        .where(product_vehicle_attributes: { value: value })
        .distinct
    end

    product_ids = products.pluck(:shopify_product_id)
    
    render json: { product_ids: product_ids, count: product_ids.length }
  end
end
