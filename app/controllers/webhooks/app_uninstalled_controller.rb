module Webhooks
  class AppUninstalledController < BaseController
    # POST /webhooks/app_uninstalled
    def create
      return head :ok if duplicate_delivery?

      Webhooks::AppUninstalledJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      record_delivery!
      head :ok
    end
  end
end
