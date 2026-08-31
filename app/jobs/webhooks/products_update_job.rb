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

      # products/update payload carries the main image as `image.src` and the
      # full set as `images[].src` — keep the primary one so the storefront can
      # render the merchant's real product photo.
      image_src = webhook.dig("image", "src") || webhook.dig("images", 0, "src")

      # Update cached product metadata (title, handle, image) in existing fitments
      # rubocop:disable-next Rails/SkipsModelValidations -- cache rows mirror Shopify data; no validations to run
      shop.vehicle_product_fitments.where(product_id: product_id).update_all(
        product_title: title,
        product_handle: handle,
        product_image: image_src.presence
      )

      Rails.logger.info("[Webhooks::ProductsUpdateJob] Updated metadata for product #{product_id} on #{shop_domain}")
    end
  end
end
