require "rails_helper"

RSpec.describe "Webhook endpoints", type: :request do
  let(:secret) { ShopifyApp.configuration.secret }
  let(:shop) { create(:shop) }

  def post_webhook(path, payload, shop_domain: shop.shopify_domain, sign: true)
    body = payload.to_json
    headers = {
      "Content-Type" => "application/json",
      "X-Shopify-Shop-Domain" => shop_domain,
      "X-Shopify-Topic" => "products/update",
      "X-Shopify-Webhook-Id" => SecureRandom.uuid
    }
    if sign
      headers["X-Shopify-Hmac-Sha256"] = Base64.strict_encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), secret, body)
      )
    end

    post path, params: body, headers: headers
  end

  before do
    # Test env is Rails.env.local?, which skips webhook HMAC verification.
    # Stub it off so these specs exercise the production path.
    allow(Rails.env).to receive(:local?).and_return(false)
  end

  describe "HMAC verification" do
    it "rejects unsigned requests" do
      post_webhook "/webhooks/products_update", { id: 1 }, sign: false
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects tampered payloads" do
      body = { id: 1 }.to_json
      forged = Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), "wrong-secret", body))
      post "/webhooks/products_update", params: body,
                                        headers: { "Content-Type" => "application/json", "X-Shopify-Hmac-Sha256" => forged,
                                                   "X-Shopify-Shop-Domain" => shop.shopify_domain }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /webhooks/products_update" do
    it "enqueues ProductsUpdateJob with the shop domain and payload" do
      payload = { id: 123, title: "Cold Air Intake", handle: "cold-air-intake" }
      expect do
        post_webhook "/webhooks/products_update", payload
      end.to have_enqueued_job(Webhooks::ProductsUpdateJob).with(
        shop_domain: shop.shopify_domain, webhook: hash_including("id" => 123)
      )
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /webhooks/products_create" do
    it "enqueues ProductsCreateJob" do
      expect do
        post_webhook "/webhooks/products_create", { id: 456, title: "New Part" }
      end.to have_enqueued_job(Webhooks::ProductsCreateJob)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /webhooks/products_delete" do
    it "enqueues ProductsDeleteJob" do
      expect do
        post_webhook "/webhooks/products_delete", { id: 789 }
      end.to have_enqueued_job(Webhooks::ProductsDeleteJob)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /webhooks/app_uninstalled" do
    it "enqueues AppUninstalledJob" do
      expect do
        post_webhook "/webhooks/app_uninstalled", { id: 1 }
      end.to have_enqueued_job(Webhooks::AppUninstalledJob).with(shop_domain: shop.shopify_domain, webhook: anything)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /webhooks/shop_redact (GDPR)" do
    it "destroys the shop and returns 200" do
      create(:vehicle_product_fitment, shop: shop)
      expect do
        post_webhook "/webhooks/shop_redact", { shop_domain: shop.shopify_domain }
      end.to change(Shop, :count).by(-1)
      expect(response).to have_http_status(:ok)
    end

    it "returns 200 for an unknown shop (nothing to erase)" do
      post_webhook "/webhooks/shop_redact", { shop_domain: "unknown.myshopify.com" }
      expect(response).to have_http_status(:ok)
    end
  end
end
