class SyncShopDataJob < ApplicationJob
  queue_as :default

  def perform(shop_data)
    shop_domain = shop_data["domain"]
    shop = Shop.find_by(shopify_domain: shop_domain)
    return unless shop

    shop.update(
      shop_data: shop_data,
      plan_name: shop_data["plan_display_name"]
    )
  end
end
