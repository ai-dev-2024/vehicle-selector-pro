module Metafields
  class ProductMetafieldSyncJob < ApplicationJob
    queue_as :sync

    retry_on Shopify::ThrottledError, wait: 5.seconds, attempts: 3

    def perform(shop_id, product_id, enqueued_updated_at = nil)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      Shopify::MetafieldSyncService.sync_product(shop, product_id)

      # Debounce tail: if a fitment write landed after this job was enqueued,
      # re-enqueue once so the newest state is pushed to Shopify. The marker
      # from the callback has usually expired by now, so this only fires when
      # there genuinely is newer data.
      if enqueued_updated_at.present?
        newest = shop.vehicle_product_fitments.where(product_id: product_id).maximum(:updated_at)
        if newest.present? && newest > Time.zone.parse(enqueued_updated_at)
          Rails.logger.info("[ProductMetafieldSyncJob] Newer fitment write detected for #{product_id}, re-syncing")
          Metafields::ProductMetafieldSyncJob.perform_later(shop_id, product_id, newest.iso8601)
        end
      end
    rescue StandardError => e
      Rails.logger.error("[ProductMetafieldSyncJob] Error syncing product #{product_id} for shop #{shop_id}: #{e.message}")
    end
  end
end
