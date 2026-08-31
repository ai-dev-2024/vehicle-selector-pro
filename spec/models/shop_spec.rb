require "rails_helper"

RSpec.describe Shop do
  describe ".store (shopify_app session storage hook)" do
    let(:auth_session) { ShopifyAPI::Auth::Session.new(shop: domain, access_token: "token_123") }
    let(:domain) { "reinstall.myshopify.com" }

    it "creates a shop on first install and returns its id" do
      id = described_class.store(auth_session)
      shop = described_class.find(id)
      expect(shop.shopify_domain).to eq(domain)
      expect(shop.shopify_token).to eq("token_123")
      expect(shop.active).to be(true)
      expect(shop.uninstalled_at).to be_nil
    end

    it "reactivates a shop that previously uninstalled (reinstall)" do
      shop = create(:shop, shopify_domain: domain, active: false, uninstalled_at: 1.hour.ago,
                           shopify_token: "revoked_old")

      id = described_class.store(auth_session)

      expect(id).to eq(shop.id)
      shop.reload
      expect(shop.active).to be(true)
      expect(shop.uninstalled_at).to be_nil
      expect(shop.shopify_token).to eq("token_123")
    end

    it "updates the token for an existing active shop" do
      create(:shop, shopify_domain: domain, active: true, shopify_token: "old_token")

      described_class.store(auth_session)

      expect(Shop.find_by(shopify_domain: domain).shopify_token).to eq("token_123")
    end
  end

  describe "lifecycle transitions" do
    it "marks a shop uninstalled and inactive" do
      shop = create(:shop)
      shop.mark_as_uninstalled!
      shop.reload
      expect(shop.active).to be(false)
      expect(shop.uninstalled_at).to be_present
      expect(shop.shopify_token).to start_with("revoked_")
    end

    it "reinstalls and restores an active shop" do
      shop = create(:shop, active: false, uninstalled_at: 2.hours.ago)
      shop.reinstall!("new_token", "read_products")
      expect(shop.active).to be(true)
      expect(shop.uninstalled_at).to be_nil
      expect(shop.shopify_token).to eq("new_token")
      expect(shop.access_scopes).to eq("read_products")
    end
  end
end
