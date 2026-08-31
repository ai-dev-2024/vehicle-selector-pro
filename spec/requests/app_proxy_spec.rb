require "rails_helper"

RSpec.describe "App Proxy endpoints", type: :request do
  let(:shop) { create(:shop) }

  # The test environment accepts the sentinel header as a valid signature
  # (see AppProxy::BaseController#verify_proxy_signature); the real HMAC
  # math is covered by AppProxySignatureVerifierSpec.
  def proxy_get(path, shop_domain: shop.shopify_domain)
    get path, params: { shop: shop_domain }, headers: { "X-Shopify-Test-Signature" => "valid" }
  end

  before do
    # Test env is Rails.env.local?, which enables dev fallbacks (shop fallback,
    # HMAC skip). Stub it off so these specs exercise the production path.
    allow(Rails.env).to receive(:local?).and_return(false)
  end

  describe "shop resolution" do
    it "rejects requests with no shop" do
      get "/apps/vehicle-selector/years"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests for an unknown shop domain" do
      proxy_get "/apps/vehicle-selector/years", shop_domain: "not-installed.myshopify.com"
      expect(response).to have_http_status(:not_found)
    end

    it "rejects requests for an uninstalled shop" do
      shop.update!(active: false)
      proxy_get "/apps/vehicle-selector/years"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /years" do
    it "returns the distinct years for the shop's fitments" do
      create(:vehicle_product_fitment, shop: shop, vehicle: create(:vehicle, year: 2020, make: "Ford", model: "F-150"))
      proxy_get "/apps/vehicle-selector/years"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["years"]).to include(2020)
    end
  end
end
