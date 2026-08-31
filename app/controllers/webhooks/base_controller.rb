require "openssl"
require "base64"
require "active_support/security_utils"

module Webhooks
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_webhook_hmac, unless: -> { Rails.env.local? }

    protected

    def shop_domain
      request.headers["X-Shopify-Shop-Domain"]
    end

    def webhook_topic
      request.headers["X-Shopify-Topic"]
    end

    def parsed_webhook_body
      @parsed_webhook_body ||= begin
        JSON.parse(request.raw_post)
      rescue StandardError
        {}
      end
    end

    def webhook_id
      request.headers["X-Shopify-Webhook-Id"]
    end

    # Shopify redelivers webhooks on failure/timeout, so the same delivery can
    # hit this endpoint twice. Returns true when this delivery is a duplicate
    # that should be acknowledged without re-enqueuing the job.
    def duplicate_delivery?
      webhook_id.present? && WebhookDelivery.exists?(
        shop_domain: shop_domain,
        webhook_id: webhook_id
      )
    end

    # Records the delivery AFTER the job has been enqueued (or handled), so a
    # failed enqueue still lets Shopify redeliver. The unique index makes
    # concurrent duplicate deliveries safe: the loser raises RecordNotUnique
    # and is treated as already recorded.
    def record_delivery!
      return true if webhook_id.blank?

      WebhookDelivery.create!(
        shop_domain: shop_domain,
        topic: webhook_topic,
        webhook_id: webhook_id,
        processed_by: "#{controller_name}##{action_name}",
        processed_at: Time.current
      )
      Webhooks::PruneWebhookDeliveriesJob.perform_later if rand < 0.01
      true
    rescue ActiveRecord::RecordNotUnique
      true
    end

    private

    def verify_webhook_hmac
      secret = ShopifyApp.configuration.secret
      hmac_header = request.headers["X-Shopify-Hmac-Sha256"]

      return head :unauthorized if secret.blank? || hmac_header.blank?

      digest = OpenSSL::Digest.new("sha256")
      calculated_hmac = Base64.strict_encode64(OpenSSL::HMAC.digest(digest, secret, request.raw_post))

      return if ActiveSupport::SecurityUtils.secure_compare(calculated_hmac, hmac_header)

      Rails.logger.warn("[Webhook Security] Invalid HMAC signature for topic: #{webhook_topic} from #{shop_domain}")
      head :unauthorized
    end
  end
end
