module Webhooks
  class ShopController < BaseController
    def redact
      Rails.logger.info("[GDPR] shop/redact shop=#{params[:shop_domain]}")
      head :ok
    end
  end
end
