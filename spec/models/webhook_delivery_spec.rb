require "rails_helper"

RSpec.describe WebhookDelivery, type: :model do
  describe ".seen?" do
    it "returns false for a new delivery and true for the replay" do
      expect(WebhookDelivery.seen?(shop_domain: "a.myshopify.com", topic: "products/update", webhook_id: "w1")).to be(false)
      expect(WebhookDelivery.seen?(shop_domain: "a.myshopify.com", topic: "products/update", webhook_id: "w1")).to be(true)
      expect(WebhookDelivery.count).to eq(1)
    end

    it "treats the same webhook_id for a different shop as distinct" do
      WebhookDelivery.seen?(shop_domain: "a.myshopify.com", topic: "products/update", webhook_id: "w1")
      expect(WebhookDelivery.seen?(shop_domain: "b.myshopify.com", topic: "products/update", webhook_id: "w1")).to be(false)
    end

    it "short-circuits on a blank webhook id (legacy deliveries)" do
      expect(WebhookDelivery.seen?(shop_domain: "a.myshopify.com", topic: "products/update", webhook_id: "")).to be(true)
    end
  end

  describe ".prune!" do
    it "removes rows older than the retention window" do
      create(:webhook_delivery, processed_at: 8.days.ago)
      create(:webhook_delivery, processed_at: 1.hour.ago)

      expect(WebhookDelivery.prune!).to eq(1)
      expect(WebhookDelivery.count).to eq(1)
    end
  end
end
