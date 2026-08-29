class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :set_shop
  skip_before_action :set_shopify_session

  before_action :verify_shopify_webhook

  private

  def verify_shopify_webhook
    data = request.raw_post
    hmac = request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"]
    
    computed_hmac = Base64.strict_encode64(
      OpenSSL::HMAC.digest("sha256", ENV["SHOPIFY_API_SECRET"], data)
    )
    
    render json: { error: "Unauthorized" }, status: :unauthorized unless computed_hmac == hmac
  end

  def webhook_params
    params.require(:webhook).permit!
  end
end
