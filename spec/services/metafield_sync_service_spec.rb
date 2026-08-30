require "rails_helper"

RSpec.describe Shopify::MetafieldSyncService do
  let(:shop) { create(:shop) }
  let(:client) { instance_double(Shopify::GraphQLClient) }
  let(:service) { described_class.new(shop) }

  before do
    allow(Shopify::GraphQLClient).to receive(:new).and_return(client)
    allow(client).to receive(:mutate).and_return(
      "metafieldsSet" => { "userErrors" => [], "metafields" => [] }
    )
  end

  def make_fitment(year, make, model)
    create(:vehicle_product_fitment, shop: shop,
                                     vehicle: create(:vehicle, year: year, make: make, model: model))
  end

  describe "#sync_products" do
    it "builds a metafieldsSet payload with YMM data and marks records synced" do
      fitment = make_fitment(2024, "Ford", "F-150")

      result = service.sync_products([fitment.product_id])

      expect(result[:success]).to be(true)
      expect(client).to have_received(:mutate) do |mutation, vars|
        expect(mutation).to include("metafieldsSet")
        mf = vars[:metafields].first
        expect(mf[:ownerId]).to eq(fitment.product_id)
        expect(mf[:namespace]).to eq("custom")
        expect(mf[:key]).to eq("vehicle_fitment")
        payload = JSON.parse(mf[:value])
        expect(payload["universal"]).to be(false)
        expect(payload["fitments"].first["make"]).to eq("Ford")
        expect(payload["ymm_keys"]).to eq(["2024|ford|f-150"])
      end
      expect(fitment.reload.synced_to_metafield).to be(true)
    end

    it "no-ops on an empty product list" do
      expect(service.sync_products([])).to eq(success: true, count: 0)
      expect(client).not_to have_received(:mutate)
    end

    it "raises on userErrors" do
      allow(client).to receive(:mutate).and_return(
        "metafieldsSet" => { "userErrors" => [{ "field" => ["value"], "message" => "Too large" }] }
      )
      fitment = make_fitment(2024, "Ford", "F-150")
      expect { service.sync_products([fitment.product_id]) }.to raise_error(Shopify::GraphQLError)
    end
  end

  describe "#sync_all" do
    it "marks the sync log completed" do
      make_fitment(2023, "Toyota", "Tacoma")
      log = instance_spy(MetafieldSyncLog)
      allow(MetafieldSyncLog).to receive(:new).and_return(log)

      result = service.sync_all(log: log)
      expect(result[:success]).to be(true)
      expect(log).to have_received(:mark_in_progress!).at_least(:once)
      expect(log).to have_received(:mark_completed!).with(1)
    end
  end
end
