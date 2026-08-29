class SyncProductAttributesJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(product_id, shop_id)
    product = Product.find_by(id: product_id, shop_id: shop_id)
    return unless product

    shop = Shop.find(shop_id)
    
    # Fetch metafields from Shopify
    metafield_query = fetch_product_metafields(shop, product.shopify_product_id)
    
    # Parse metafields and sync to local database
    sync_metafields_to_database(product, metafield_query, shop)
    
    product.update(last_metafield_sync: Time.current)
  end

  private

  def fetch_product_metafields(shop, shopify_product_id)
    query = <<~GQL
      query {
        product(id: "gid://shopify/Product/#{shopify_product_id}") {
          metafields(first: 100, namespace: "vehicle_selector") {
            edges {
              node {
                id
                key
                value
                valueType
              }
            }
          }
        }
      }
    GQL

    ShopifyAPI::GraphQL.execute(query, api_version: "2024-01", shop_url: shop.shopify_domain)
  end

  def sync_metafields_to_database(product, metafield_data, shop)
    metafield_data["data"]["product"]["metafields"]["edges"].each do |edge|
      metafield = edge["node"]
      attribute_type = metafield["key"]
      value = metafield["value"]

      vehicle_attribute = shop.vehicle_attributes.by_type(attribute_type).first
      next unless vehicle_attribute

      ProductVehicleAttribute.find_or_create_by(
        product: product,
        vehicle_attribute: vehicle_attribute,
        shop: shop
      ).update(value: value, metafield_id: metafield["id"], synced_at: Time.current)
    end
  end
end
