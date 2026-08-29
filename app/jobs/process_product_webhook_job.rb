class ProcessProductWebhookJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 5

  def perform(product_data, action)
    shop_domain = product_data["admin_graphql_api_id"]&.split("/").last
    return unless shop_domain

    shop = Shop.find_by(shopify_shop_id: shop_domain)
    return unless shop

    case action
    when "create", "update"
      sync_product(shop, product_data)
    when "delete"
      delete_product(shop, product_data["id"])
    end
  end

  private

  def sync_product(shop, product_data)
    product = Product.find_or_create_by(
      shop: shop,
      shopify_product_id: product_data["id"]
    )

    product.update_from_shopify(product_data)
    
    # Process metafields for vehicle attributes
    SyncProductAttributesJob.perform_later(product.id, shop.id)
  end

  def delete_product(shop, shopify_product_id)
    product = Product.find_by(shop: shop, shopify_product_id: shopify_product_id)
    product&.destroy
  end
end
