module Webhooks
  class CustomersController < BaseController
    # Mandatory GDPR webhooks. This app does not store customer PII (no
    # customers table — shoppers' vehicles live in their browser's
    # localStorage), so both handlers only acknowledge receipt. They must still
    # be registered in the Partners Dashboard and return 200 for App Store
    # review; shop-scoped data erasure itself is handled by shop/redact.
    def data_request
      Rails.logger.info("[GDPR] customers/data_request shop=#{shop_domain} customer_id=#{customer_id}")
      head :ok
    end

    def redact
      Rails.logger.info("[GDPR] customers/redact shop=#{shop_domain} customer_id=#{customer_id}")
      head :ok
    end

    private

    # Log the id only. The payload also carries the customer's email and
    # phone number, which must not end up in application logs.
    def customer_id
      customer = parsed_webhook_body["customer"]
      customer["id"] if customer.is_a?(Hash)
    end
  end
end
