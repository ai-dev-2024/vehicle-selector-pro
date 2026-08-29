class Product < ApplicationRecord
  belongs_to :shop
  has_many :product_vehicle_attributes, dependent: :destroy
  has_many :vehicle_attributes, through: :product_vehicle_attributes

  validates :shop_id, :shopify_product_id, :title, presence: true
  validates :shopify_product_id, uniqueness: { scope: :shop_id }

  scope :active, -> { where(active: true) }
  scope :synced_recently, -> { where("synced_at > ?", 24.hours.ago) }

  def vehicle_attributes_for_sale
    product_vehicle_attributes.includes(:vehicle_attribute)
  end

  def get_attribute_value(attribute_type)
    product_vehicle_attributes
      .joins(:vehicle_attribute)
      .where(vehicle_attributes: { attribute_type: attribute_type })
      .pluck(:value)
      .first
  end

  def update_from_shopify(product_data)
    update(
      title: product_data["title"],
      description: product_data["body_html"],
      product_data: product_data,
      synced_at: Time.current
    )
  end

  def sync_metafields_to_shopify!
    # Sync product vehicle attributes to Shopify metafields
    # This will be implemented in the Shopify service
  end
end
