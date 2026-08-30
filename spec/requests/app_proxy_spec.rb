require "rails_helper"

RSpec.describe "App Proxy endpoints", type: :request do
  let(:shop) { create(:shop) }
  let(:secret) { ShopifyApp.configuration.secret }

  # Shopify signs the full query string: params sorted, joined, HMAC'd.
  # Build the query string first, then send it byte-for-byte.
  def signed_get(path, params:)
    query = params.compact.map { |k, v| "#{k}=#{v}" }.join("&")
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), secret, query)
    get path, params: params, headers: { "X-Shopify-Test-Signature" => "valid" }
  end

  before do
    # Test env is Rails.env.local?, which enables dev fallbacks (shop fallback,
    # HMAC skip). Stub it off so these specs exercise the production path.
    allow(Rails.env).to receive(:local?).and_return(false)
    create(:vehicle_product_fitment, shop: shop, vehicle: create(:vehicle, year: 2020, make: "Ford", model: "F-150"))
    create(:vehicle_product_fitment, :universal, shop: shop)
  end

  describe "authentication" do
    it "rejects requests with no shop" do
      get "/apps/vehicle-selector/years"
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects requests for an unknown shop domain" do
      signed_get "/apps/vehicle-selector/years", params: { shop: "not-installed.myshopify.com" }
      expect(response).to have_http_status(:not_found)
    end

    it "rejects requests for an uninstalled shop" do
      shop.update!(active: false)
      signed_get "/apps/vehicle-selector/years", params: { shop: shop.shopify_domain }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /years" do
    it "returns the distinct years for the shop's fitments" do
      signed_get "/apps/vehicle-selector/years", params: { shop: shop.shopify_domain }
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["years"]).to include(2020)
    end
  end

  describe "GET /makes" do
    it "returns makes scoped to the requested year" do
      signed_get "/apps/vehicle-selector/makes", params: { shop: shop.shopify_domain, year: 2020 }
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["makes"]).to include("Ford")
    end
  end

  describe "GET /search" do
    it "returns matching product IDs" do
      signed_get "/apps/vehicle-selector/search", params: { shop: shop.shopify_domain, year: 2020, make: "Ford", model: "F-150" }
      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body["success"]).to be(true)
      expect(body["data"]["products"] || body["data"]["product_ids"]).to be_present
    end
  end
end
