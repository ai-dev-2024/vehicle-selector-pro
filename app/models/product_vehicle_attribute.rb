class ProductVehicleAttribute < ApplicationRecord
  belongs_to :product
  belongs_to :vehicle_attribute
  belongs_to :shop

  validates :product_id, :vehicle_attribute_id, :shop_id, :value, presence: true
  validates :product_id, uniqueness: { scope: :vehicle_attribute_id }

  scope :for_shop, ->(shop_id) { where(shop_id: shop_id) }
  scope :for_attribute_type, ->(type) {
    joins(:vehicle_attribute).where(vehicle_attributes: { attribute_type: type })
  }

  def attribute_type
    vehicle_attribute.attribute_type
  end

  def attribute_label
    vehicle_attribute.label
  end
end
