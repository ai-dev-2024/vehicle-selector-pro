module Webhooks
  class CustomersController < BaseController
    def data_request
      Rails.logger.info("[GDPR] customers/data_request shop=#{params[:shop_domain]} customer=#{params[:customer]}")
      head :ok
    end

    def redact
      Rails.logger.info("[GDPR] customers/redact shop=#{params[:shop_domain]} customer=#{params[:customer]}")
      head :ok
    end
  end
end
