module AppProxy
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_proxy_signature, unless: -> { Rails.env.development? && params[:skip_proxy_verify] == "true" }
    before_action :set_current_shop
    before_action :set_cache_headers

    rescue_from StandardError, with: :handle_standard_error

    protected

    attr_reader :current_shop

    def fitment_search_service
      @fitment_search_service ||= FitmentSearchService.new(current_shop)
    end

    private

    def verify_proxy_signature
      return if AppProxySignatureVerifier.valid?(request.query_parameters)

      # In test environment, allow simulated signature or header
      return if Rails.env.test? && (request.headers["X-Shopify-Test-Signature"] == "valid" || params[:signature] == "test_valid_signature")

      render json: { error: "Invalid Shopify App Proxy signature" }, status: :unauthorized
    end

    def set_current_shop
      shop_domain = params[:shop].presence || request.headers["X-Shopify-Shop-Domain"]
      @current_shop = Shop.active.find_by(shopify_domain: shop_domain)

      @current_shop = Shop.active.first || Shop.first if @current_shop.nil? && (Rails.env.local?)

      return if @current_shop

      render json: { error: "Shop '#{shop_domain}' not found or inactive" }, status: :not_found
    end

    def set_cache_headers
      # Dynamic App Proxy responses are cached with stale-while-revalidate
      response.headers["Cache-Control"] = "public, max-age=180, stale-while-revalidate=360"
      response.headers["Vary"] = "Accept, X-Shopify-Shop-Domain"

      # ETag lets Shopify's proxy layer and browser/CDN caches return 304
      # Not Modified when nothing changed, saving bandwidth on the cascading
      # dropdown and search endpoints. Fresh responses get a strong ETag;
      # conditional requests (If-None-Match) short-circuit in the middleware.
      etag = response_etag
      response.headers["ETag"] = %("#{etag}") if etag
      return unless request.headers["If-None-Match"] == %("#{etag}") && etag

      response.status = 304
      response.body = ""
    end

    def response_etag
      shop_version = FitmentSearchService.shop_version(current_shop.id)
      [shop_version, current_shop.id, params.permit!.to_h.sort].join("|")
    end

    def handle_standard_error(exception)
      Rails.logger.error("[AppProxy Error] #{exception.class}: #{exception.message}\n#{exception.backtrace.first(5).join("\n")}")
      render json: {
        error: "An internal error occurred processing the vehicle request",
        details: Rails.env.development? ? exception.message : nil
      }, status: :internal_server_error
    end
  end
end
