module Webhooks
  class ShopUpdatesController < BaseController
    # POST /webhooks/shop_update
    def create
      return head :ok if duplicate_delivery?

      shop = Shop.find_by(shopify_domain: shop_domain)
      if shop.present?
        data = parsed_webhook_body
        shop.update(
          name: data["name"],
          email: data["email"],
          currency: data["currency"],
          iana_timezone: data["iana_timezone"]
        )
      end
      record_delivery!
      head :ok
    end
  end
end
