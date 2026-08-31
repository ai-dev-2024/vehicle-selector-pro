class VehicleProductFitment < ApplicationRecord
  include ShopScoped
  include Cacheable

  # Associations
  belongs_to :vehicle, optional: true

  # Validations
  validates :product_id, presence: true
  validates :vehicle, presence: true, unless: :universal_fit?
  validates :vehicle_id, uniqueness: {
    scope: %i[shop_id product_id],
    message: :fitment_already_exists,
    unless: :universal_fit?
  }
  validates :product_id, uniqueness: {
    scope: :shop_id,
    message: :already_marked_universal,
    if: :universal_fit?
  }

  # Scopes
  scope :universal, -> { where(universal_fit: true) }
  scope :specific, -> { where(universal_fit: false) }
  scope :synced, -> { where(synced_to_metafield: true) }
  scope :pending_sync, -> { where(synced_to_metafield: false) }
  scope :for_product, ->(product_id) { where(product_id: product_id.to_s) }
  scope :for_vehicle, ->(vehicle_id) { where(vehicle_id: vehicle_id) }

  # Callbacks
  after_commit :enqueue_metafield_sync, on: %i[create update destroy]

  def universal_fit?
    universal_fit == true
  end

  def to_fitment_hash
    {
      id: id,
      product_id: product_id,
      product_handle: product_handle,
      product_title: product_title,
      sku: sku,
      brand: brand,
      category: category,
      price_cents: price_cents,
      short_description: short_description,
      universal_fit: universal_fit,
      fitment_type: fitment_type,
      fitment_notes: fitment_notes,
      position: position,
      vehicle: vehicle&.to_h
    }
  end

  private

  def enqueue_metafield_sync
    # Only enqueue if shop is active and product_id is present
    return unless shop&.active? && product_id.present?

    Metafields::ProductMetafieldSyncJob.perform_later(shop_id, product_id)
  rescue StandardError => e
    Rails.logger.warn("[FitmentSyncCallback] Could not enqueue background sync: #{e.message}")
  end
end
