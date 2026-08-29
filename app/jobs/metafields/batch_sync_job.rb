module Metafields
  class BatchSyncJob < ApplicationJob
    queue_as :sync

    retry_on Shopify::ThrottledError, wait: :polynomially_longer, attempts: 5

    def perform(shop_id, product_ids = nil, log_id = nil)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      log = MetafieldSyncLog.find_by(id: log_id)

      if product_ids.present?
        Shopify::MetafieldSyncService.new(shop).sync_products(product_ids)
        log&.mark_completed!(product_ids.size)
      else
        Shopify::MetafieldSyncService.sync_all_products(shop, log: log)
      end
    rescue StandardError => e
      log&.mark_failed!(e)
      Rails.logger.error("[BatchSyncJob] Failed: #{e.message}")
      raise e
    end
  end
end
