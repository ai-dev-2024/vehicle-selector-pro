module Webhooks
  class AppUninstalledController < BaseController
    # POST /webhooks/app_uninstalled
    def create
      Webhooks::AppUninstalledJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      head :ok
    end
  end
end
