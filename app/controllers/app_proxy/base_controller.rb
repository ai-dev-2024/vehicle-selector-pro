module AppProxy
  class BaseController < ActionController::Base
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
      if Rails.env.test? && (request.headers["X-Shopify-Test-Signature"] == "valid" || params[:signature] == "test_valid_signature")
        return
      end

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
