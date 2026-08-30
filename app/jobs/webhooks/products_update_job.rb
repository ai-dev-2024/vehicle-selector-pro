module Webhooks
  class ProductsUpdateJob < ApplicationJob
    queue_as :webhooks

    def perform(shop_domain:, webhook:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      unless shop&.active?
        Rails.logger.warn(
          "[Webhooks::ProductsUpdateJob] Dropped webhook for missing/inactive shop: #{shop_domain}"
        )
        return
      end

      product_id = webhook["admin_graphql_api_id"] || "gid://shopify/Product/#{webhook['id']}"
      title = webhook["title"]
      handle = webhook["handle"]

      # Update cached product title and handle in existing fitments
      # rubocop:disable-next Rails/SkipsModelValidations -- cache rows mirror Shopify data; no validations to run
      shop.vehicle_product_fitments.where(product_id: product_id).update_all(
        product_title: title,
        product_handle: handle
      )

      Rails.logger.info("[Webhooks::ProductsUpdateJob] Updated metadata for product #{product_id} on #{shop_domain}")
    end
  end
end
