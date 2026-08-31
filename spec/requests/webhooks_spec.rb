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

  describe "topic dispatch" do
    # [path, job, payload]
    cases = [
      ["/webhooks/products_update", Webhooks::ProductsUpdateJob,
       { id: 123, title: "Cold Air Intake", handle: "cold-air-intake" }],
      ["/webhooks/products_create", Webhooks::ProductsCreateJob, { id: 456, title: "New Part" }],
      ["/webhooks/products_delete", Webhooks::ProductsDeleteJob, { id: 789 }],
      ["/webhooks/app_uninstalled", Webhooks::AppUninstalledJob, { id: 1 }]
    ]

    cases.each do |path, job, payload|
      it "enqueues #{job.name.demodulize} for #{path} and acks with 200" do
        expect { post_webhook path, payload }.to have_enqueued_job(job).with(
          shop_domain: shop.shopify_domain,
          webhook: hash_including("id" => payload[:id])
        )
        expect(response).to have_http_status(:ok)
      end
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
