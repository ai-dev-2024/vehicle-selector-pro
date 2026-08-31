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

    it "returns nil when the shop already has a billable subscription" do
      allow(client).to receive(:query).and_return(
        "currentAppInstallation" => {
          "activeSubscriptions" => [{ "id" => "1", "name" => "Vehicle Selector Pro — Pro", "test" => true }]
        }
      )

      expect(client).not_to receive(:mutate)
      expect(described_class.new(shop).create_subscription("plus")).to be_nil
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
