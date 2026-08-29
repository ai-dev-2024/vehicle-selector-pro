class AppProxyController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_shop
  skip_before_action :set_shopify_session

  before_action :verify_shopify_proxy_request
  before_action :set_shop_from_proxy

  private

  def verify_shopify_proxy_request
    # Verify the proxy request signature
    encoded_params = params.except(:action, :controller)
    computed_hmac = compute_hmac(encoded_params)
    request_hmac = request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"]

    render json: { error: "Unauthorized" }, status: :unauthorized unless computed_hmac == request_hmac
  end

  def compute_hmac(params)
    encoded = params.except(:hmac, :signature).sort.map { |k, v| "#{k}=#{v}" }.join("&")
    Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", ENV["SHOPIFY_API_SECRET"], encoded))
  end

  def set_shop_from_proxy
    shop_domain = request.headers["HTTP_X_SHOPIFY_SHOP_API_ACCESS_TOKEN"]
    @shop = Shop.find_by(shopify_domain: shop_domain)
    render json: { error: "Shop not found" }, status: :not_found unless @shop
  end
end
