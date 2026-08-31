# Records every processed Shopify webhook delivery. Shopify redelivers
# webhooks when an endpoint returns non-2xx or times out, so a delivery
# can arrive more than once; the unique (shop_domain, webhook_id) index
# makes duplicate processing idempotent. Rows are kept briefly for the
# dedup window and pruned by a periodic job.
class WebhookDelivery < ApplicationRecord
  STATUSES = %w[processed failed].freeze

  validates :shop_domain, presence: true
  validates :topic, presence: true
  validates :webhook_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :stale, -> { where(processed_at: ...7.days.ago) }

  # Atomically marks this delivery as seen. Returns true when this delivery
  # is new (the caller should process it), false when it was already handled.
  def self.seen?(shop_domain:, topic:, webhook_id:, processed_by: nil)
    return true if webhook_id.blank?

    create!(
      shop_domain: shop_domain,
      topic: topic,
      webhook_id: webhook_id,
      processed_by: processed_by,
      processed_at: Time.current
    )
    false
  rescue ActiveRecord::RecordNotUnique
    true
  end

  # Housekeeping: drop dedup rows older than the retention window so the
  # table stays small even on busy stores.
  def self.prune!
    stale.delete_all
  end
end
