module Webhooks
  class ProductsCreateJob < ApplicationJob
    queue_as :webhooks

    def perform(shop_domain:, webhook:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      unless shop&.active?
        Rails.logger.warn(
          "[Webhooks::ProductsCreateJob] Dropped webhook for missing/inactive shop: #{shop_domain}"
        )
        return
      end

      product_id = webhook["admin_graphql_api_id"] || "gid://shopify/Product/#{webhook['id']}"
      Rails.logger.info("[Webhooks::ProductsCreateJob] New product #{product_id} received for #{shop_domain}")
    end
  end
end
