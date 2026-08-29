module Webhooks
  class ProductsController < BaseController
    # POST /webhooks/products_create
    def create
      Webhooks::ProductsCreateJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      head :ok
    end

    # POST /webhooks/products_update
    def update
      Webhooks::ProductsUpdateJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      head :ok
    end

    # POST /webhooks/products_delete
    def destroy
      Webhooks::ProductsDeleteJob.perform_later(
        shop_domain: shop_domain,
        webhook: parsed_webhook_body
      )
      head :ok
    end
  end
end
