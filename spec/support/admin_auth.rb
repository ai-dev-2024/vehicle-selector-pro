# Authenticates a request spec as a registered Shopify admin. The session
# repository is the Shop model, so we store a session for the given shop and
# stub the base controller's current_shopify_session to return it.
module AdminAuth
  def authenticate_admin!(shop)
    allow(Rails.env).to receive(:local?).and_return(false)
    session_id = ShopifyApp::SessionRepository.store_shop_session(
      ShopifyAPI::Auth::Session.new(shop: shop.shopify_domain, access_token: shop.shopify_token)
    )
    allow_any_instance_of(Admin::BaseController).to receive(:current_shopify_session).and_return(
      ShopifyApp::SessionRepository.retrieve_shop_session(session_id)
    )
  end
end

RSpec.configure do |config|
  config.include AdminAuth, type: :request
end
