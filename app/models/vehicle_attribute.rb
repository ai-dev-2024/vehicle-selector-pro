class VehicleAttribute < ApplicationRecord
  belongs_to :shop
  has_many :vehicle_attribute_values, dependent: :destroy
  has_many :product_vehicle_attributes, dependent: :destroy
  has_many :products, through: :product_vehicle_attributes

  validates :shop_id, :attribute_type, :label, presence: true
  validates :attribute_type, uniqueness: { scope: :shop_id }

  scope :active, -> { where(active: true) }
  scope :by_type, ->(type) { where(attribute_type: type) }

  ATTRIBUTE_TYPES = %w[year make model trim engine transmission body_type].freeze

  def self.attribute_types
    ATTRIBUTE_TYPES
  end

  def available_values
    vehicle_attribute_values.active.order(:sort_order, :value)
  end

  def sync_with_metafield!
    # Sync with Shopify metafields
    # This will be implemented in the Shopify integration service
  end
end
