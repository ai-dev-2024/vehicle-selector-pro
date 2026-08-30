module Webhooks
  class CustomersController < BaseController
    # Mandatory GDPR webhooks. This app does not store customer PII (no
    # customers table — shoppers' vehicles live in their browser's
    # localStorage), so both handlers only acknowledge receipt. They must still
    # be registered in the Partners Dashboard and return 200 for App Store
    # review; shop-scoped data erasure itself is handled by shop/redact.
    def data_request
      Rails.logger.info("[GDPR] customers/data_request shop=#{shop_domain} customer=#{params[:customer]}")
      head :ok
    end

    def redact
      Rails.logger.info("[GDPR] customers/redact shop=#{shop_domain} customer=#{params[:customer]}")
      head :ok
    end
  end
end
