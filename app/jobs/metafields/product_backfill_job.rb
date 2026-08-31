module Metafields
  # Background worker for the admin "Backfill from Shopify" action. Pulls the
  # merchant's products and refreshes cached title / handle / image on mapped
  # fitments, recording a MetafieldSyncLog row so the Sync page shows results.
  class ProductBackfillJob < ApplicationJob
    queue_as :sync

    retry_on Shopify::ThrottledError, wait: :polynomially_longer, attempts: 5

    def perform(shop_id, log_id = nil)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      log = MetafieldSyncLog.find_by(id: log_id)
      log&.mark_in_progress!(shop.unique_products_count)

      report = Shopify::ProductBackfillService.new(shop).run

      log&.update!(
        status: "completed",
        total_products: [report[:products], shop.unique_products_count].max,
        synced_products: report[:fitments_updated],
        error_details: report[:errors].flatten.join("; ").presence,
        completed_at: Time.current
      )

      Rails.logger.info("[ProductBackfillJob] shop=#{shop.id} products=#{report[:products]} " \
                        "fitments_updated=#{report[:fitments_updated]} errors=#{report[:errors].size}")
      report
    rescue StandardError => e
      log&.mark_failed!(e)
      Rails.logger.error("[ProductBackfillJob] Failed for shop #{shop_id}: #{e.message}")
      raise
    end
  end
end
