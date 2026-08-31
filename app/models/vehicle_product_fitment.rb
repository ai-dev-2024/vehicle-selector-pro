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

  # Confidence score per fitment type. Universal fitments are the least
  # specific; OEM/engine-matched direct fits are the most. Kept as a column so
  # storefront queries can sort by it without computing on read.
  CONFIDENCE_BY_TYPE = {
    "oem" => 1.0,
    "direct_fit" => 0.9,
    "modified" => 0.5,
    "universal" => 0.4
  }.freeze

  # Callbacks
  before_validation :compute_confidence_score
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
      product_image: product_image,
      universal_fit: universal_fit,
      fitment_type: fitment_type,
      confidence_score: confidence_score.to_f,
      fitment_notes: fitment_notes,
      position: position,
      vehicle: vehicle&.to_h
    }
  end

  private

  def compute_confidence_score
    self.confidence_score = CONFIDENCE_BY_TYPE.fetch(fitment_type.to_s, 0.9)
  end

  def enqueue_metafield_sync
    # Only enqueue if shop is active and product_id is present
    return unless shop&.active? && product_id.present?

    # Debounce: a bulk import or multi-row edit touches the same product many
    # times in quick succession, and each commit would enqueue a sync job. A
    # short cache marker coalesces those into one job per product per window.
    # The job captures the newest updated_at at enqueue time and re-enqueues
    # once if a newer write lands while it is queued/running, so the final
    # state is always synced (eventually consistent, never lost).
    debounce_key = "vsp/debounce/#{shop_id}/#{product_id}"
    if Rails.cache.exist?(debounce_key)
      Rails.logger.debug { "[FitmentSyncCallback] Debounced sync for product #{product_id} (shop #{shop_id})" }
      return
    end
    Rails.cache.write(debounce_key, true, expires_in: 30.seconds)

    max_updated_at = shop.vehicle_product_fitments
                         .where(product_id: product_id)
                         .maximum(:updated_at)
    Metafields::ProductMetafieldSyncJob.perform_later(shop_id, product_id, max_updated_at&.iso8601)
  rescue StandardError => e
    Rails.logger.warn("[FitmentSyncCallback] Could not enqueue background sync: #{e.message}")
  end
end
