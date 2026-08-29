require 'openssl'
require 'base64'
require 'active_support/security_utils'

module Webhooks
  class BaseController < ActionController::Base
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_hmac, unless: -> { Rails.env.development? || Rails.env.test? }

    protected

    def shop_domain
      request.headers['X-Shopify-Shop-Domain']
    end

    def webhook_topic
      request.headers['X-Shopify-Topic']
    end

    def parsed_webhook_body
      @parsed_webhook_body ||= JSON.parse(request.raw_post) rescue {}
    end

    private

    def verify_webhook_hmac
      secret = ShopifyApp.configuration.secret
      hmac_header = request.headers['X-Shopify-Hmac-Sha256']

      return head :unauthorized if secret.blank? || hmac_header.blank?

      digest = OpenSSL::Digest.new('sha256')
      calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, request.raw_post))

      unless ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)
        Rails.logger.warn("[Webhook Security] Invalid HMAC signature for topic: #{webhook_topic} from #{shop_domain}")
        head :unauthorized
      end
    end
  end
end
