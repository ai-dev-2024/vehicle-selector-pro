module Webhooks
  class ProductsDeleteJob < ApplicationJob
    queue_as :webhooks

    def perform(shop_domain:, webhook:)
      shop = Shop.find_by(shopify_domain: shop_domain)
      return unless shop

      product_id = webhook["admin_graphql_api_id"] || "gid://shopify/Product/#{webhook['id']}"

      # Clean up orphaned fitment records for the deleted product. delete_all,
      # not destroy_all: the destroy callback would enqueue a metafield sync
      # for a product Shopify has just removed. The storefront cache is
      # invalidated by hand because callbacks are skipped.
      deleted_count = shop.vehicle_product_fitments.for_product(product_id).delete_all
      FitmentSearchService.invalidate_shop_cache(shop.id)
      Rails.logger.info(
        "[Webhooks::ProductsDeleteJob] Removed #{deleted_count} fitments for deleted product #{product_id} on #{shop_domain}"
      )
    end
  end
end
