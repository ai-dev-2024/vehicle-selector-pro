class MetafieldSyncLog < ApplicationRecord
  include ShopScoped

  STATUSES = %w[pending in_progress completed failed].freeze
  SYNC_TYPES = %w[single batch full webhook].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :sync_type, inclusion: { in: SYNC_TYPES }

  scope :recent, -> { order(created_at: :desc) }
  scope :in_progress, -> { where(status: "in_progress") }
  scope :failed, -> { where(status: "failed") }

  def mark_in_progress!(total = 0)
    update!(
      status: "in_progress",
      total_products: total,
      started_at: Time.current
    )
  end

  def mark_completed!(synced = total_products)
    update!(
      status: "completed",
      synced_products: synced,
      completed_at: Time.current
    )
  end

  def mark_failed!(error)
    update!(
      status: "failed",
      error_details: error.is_a?(StandardError) ? "#{error.class}: #{error.message}\n#{error.backtrace&.first(5)&.join("\n")}" : error.to_s,
      completed_at: Time.current
    )
  end

  def progress_percentage
    return 0 if total_products.to_i.zero?

    ((synced_products.to_f / total_products) * 100).round(1)
  end
end
