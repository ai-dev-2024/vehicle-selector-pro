module Webhooks
  class ProductsController < BaseController
    # POST /webhooks/products_create
    def create
      return head :ok if duplicate_delivery?

      Webhooks::ProductsCreateJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      record_delivery!
      head :ok
    end

    # POST /webhooks/products_update
    def update
      return head :ok if duplicate_delivery?

      Webhooks::ProductsUpdateJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      record_delivery!
      head :ok
    end

    # POST /webhooks/products_delete
    def destroy
      return head :ok if duplicate_delivery?

      Webhooks::ProductsDeleteJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      record_delivery!
      head :ok
    end
  end
end
