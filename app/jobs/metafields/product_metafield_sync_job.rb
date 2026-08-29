module Metafields
  class ProductMetafieldSyncJob < ApplicationJob
    queue_as :sync

    retry_on Shopify::ThrottledError, wait: 5.seconds, attempts: 3

    def perform(shop_id, product_id)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      Shopify::MetafieldSyncService.sync_product(shop, product_id)
    rescue StandardError => e
      Rails.logger.error("[ProductMetafieldSyncJob] Error syncing product #{product_id} for shop #{shop_id}: #{e.message}")
    end
  end
end
