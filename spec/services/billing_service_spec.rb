require "rails_helper"

RSpec.describe Shopify::BillingService do
  let(:shop) { create(:shop) }
  let(:client) { instance_double(Shopify::GraphQLClient) }

  before do
    allow(Shopify::GraphQLClient).to receive(:new).and_return(client)
    # By default there are no active subscriptions; individual tests override.
    allow(client).to receive(:query).and_return(
      "currentAppInstallation" => { "activeSubscriptions" => [] }
    )
  end

  describe "#create_subscription" do
    it "returns the confirmation URL for a paid plan" do
      expect(client).to receive(:mutate).and_return(
        "appSubscriptionCreate" => {
          "appSubscription" => { "id" => "gid://shopify/AppSubscription/1", "name" => "Vehicle Selector Pro — Pro" },
          "confirmationUrl" => "https://checkout.example/confirm",
          "userErrors" => []
        }
      )

      url = described_class.new(shop).create_subscription("pro")
      expect(url).to eq("https://checkout.example/confirm")
    end

    context "when the shop is already on Pro" do
      before do
        allow(client).to receive(:query).and_return(
          "currentAppInstallation" => {
            "activeSubscriptions" => [{ "id" => "1", "name" => "Vehicle Selector Pro — Pro", "test" => true }]
          }
        )
      end

      it "returns nil for the same plan instead of creating a second charge" do
        expect(client).not_to receive(:mutate)
        expect(described_class.new(shop).create_subscription("pro")).to be_nil
      end

      # Shopify replaces the active subscription when the new one is approved,
      # so an upgrade must reach the confirmation URL.
      it "lets the merchant switch to Pro Plus" do
        expect(client).to receive(:mutate).and_return(
          "appSubscriptionCreate" => { "confirmationUrl" => "https://checkout.example/upgrade", "userErrors" => [] }
        )

        expect(described_class.new(shop).create_subscription("plus")).to eq("https://checkout.example/upgrade")
      end
    end

    it "returns nil for the free tier, which has no subscription to create" do
      expect(client).not_to receive(:mutate)
      expect(described_class.new(shop).create_subscription("free")).to be_nil
    end

    it "returns nil for an unknown plan" do
      expect(client).not_to receive(:mutate)
      expect(described_class.new(shop).create_subscription("nonexistent")).to be_nil
    end

    it "raises GraphQLError when Shopify reports user errors" do
      expect(client).to receive(:mutate).and_return(
        "appSubscriptionCreate" => { "confirmationUrl" => nil, "userErrors" => [{ "field" => ["x"], "message" => "Declined" }] }
      )

      expect { described_class.new(shop).create_subscription("pro") }
        .to raise_error(Shopify::GraphQLError, /Declined/)
    end
  end

  describe "#active_plan_key" do
    it "maps an active Pro chart back to the pro key" do
      # Non-production env keeps test subscriptions; report the chart as test.
      expect(client).to receive(:query).and_return(
        "currentAppInstallation" => {
          "activeSubscriptions" => [{ "id" => "1", "name" => "Vehicle Selector Pro — Pro", "test" => true }]
        }
      )
      expect(described_class.new(shop).active_plan_key).to eq("pro")
    end

    it "returns nil when nothing is active" do
      expect(described_class.new(shop).active_plan_key).to be_nil
    end
  end
end
