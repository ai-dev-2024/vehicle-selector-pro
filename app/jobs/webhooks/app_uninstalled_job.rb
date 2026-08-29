module Webhooks
  class AppUninstalledJob < ApplicationJob
    queue_as :webhooks

    def perform(shop_domain:, webhook:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      return unless shop

      shop.mark_as_uninstalled!
      Rails.logger.info("[Webhooks::AppUninstalledJob] Successfully marked shop #{shop_domain} as uninstalled")
    end
  end
end
