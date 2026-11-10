module Metafields
  class ProductMetafieldSyncJob < ApplicationJob
    queue_as :sync

    retry_on Shopify::ThrottledError, wait: 5.seconds, attempts: 3
    # A 401/403 means the token was revoked (uninstall) or is a placeholder
    # (seeded demo shop); a retry cannot succeed.
    discard_on Shopify::AuthenticationError

    # Errors are deliberately not rescued here: they must reach the retry
    # handlers above and in ApplicationJob, or a failed sync is lost for good.
    def perform(shop_id, product_id, enqueued_updated_at = nil)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      Shopify::MetafieldSyncService.sync_product(shop, product_id)

      # Debounce tail: if a fitment write landed after this job was enqueued,
      # re-enqueue once so the newest state is pushed to Shopify. The marker
      # from the callback has usually expired by now, so this only fires when
      # there genuinely is newer data.
      return if enqueued_updated_at.blank?

      newest = shop.vehicle_product_fitments.for_product(product_id).maximum(:updated_at)
      return unless newest.present? && newest > Time.zone.parse(enqueued_updated_at)

      Rails.logger.info("[ProductMetafieldSyncJob] Newer fitment write detected for #{product_id}, re-syncing")
      Metafields::ProductMetafieldSyncJob.perform_later(shop_id, product_id, newest.iso8601)
    end
  end
end
