class VehicleAttributeValue < ApplicationRecord
  belongs_to :vehicle_attribute
  belongs_to :shop

  validates :vehicle_attribute_id, :shop_id, :value, presence: true
  validates :value, uniqueness: { scope: :vehicle_attribute_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order, :value) }

  before_save :set_display_name

  private

  def set_display_name
    self.display_name ||= value
  end
end
