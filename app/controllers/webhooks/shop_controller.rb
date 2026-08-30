module Webhooks
  class ShopController < BaseController
    # Mandatory GDPR webhook: Shopify asks the app to erase all data it holds
    # for a store. This app stores no customer PII, but it does store shop-owned
    # fitment/vehicle-product data, sync logs and settings — destroy the shop
    # row so all of it is removed via dependent: :destroy.
    def redact
      domain = shop_domain
      shop = Shop.find_by(shopify_domain: domain)
      if shop
        Rails.logger.info("[GDPR] shop/redact erasing shop-scoped data for #{domain}")
        shop.destroy
      else
        Rails.logger.info("[GDPR] shop/redact received for #{domain} — no local data to erase")
      end
      head :ok
    end
  end
end
