module Webhooks
  class ProductsDeleteJob < ApplicationJob
    queue_as :webhooks

    def perform(shop_domain:, webhook:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      return unless shop

      product_id = webhook['admin_graphql_api_id'] || "gid://shopify/Product/#{webhook['id']}"

      # Clean up orphaned fitment records for deleted product
      deleted_count = shop.vehicle_product_fitments.where(product_id: product_id).destroy_all.size
      Rails.logger.info("[Webhooks::ProductsDeleteJob] Removed #{deleted_count} fitments for deleted product #{product_id} on #{shop_domain}")
    end
  end
end
