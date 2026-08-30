require "rails_helper"

RSpec.describe FitmentSearchService do
  let(:shop) { create(:shop) }
  let(:service) { described_class.new(shop) }

  before { Rails.cache.clear }

  def make_fitment(year, make, model, trim: nil, engine: nil, universal: false)
    fitment =
      if universal
        create(:vehicle_product_fitment, :universal, shop: shop)
      else
        create(:vehicle_product_fitment, shop: shop,
                                         vehicle: create(:vehicle, year: year, make: make, model: model,
                                                                   trim: trim, engine: engine))
      end
    Rails.cache.clear
    fitment
  end

  describe "#years" do
    it "returns distinct years descending" do
      make_fitment(2020, "Ford", "F-150")
      make_fitment(2019, "Ford", "F-150")
      expect(service.years).to eq([2020, 2019])
    end

    it "is shop-scoped" do
      make_fitment(2020, "Ford", "F-150")
      other = create(:shop)
      create(:vehicle_product_fitment, shop: other, vehicle: create(:vehicle, year: 1999, make: "Dodge", model: "Ram"))
      expect(service.years).to eq([2020])
    end
  end

  describe "#makes" do
    it "returns makes for a year, blank-safe" do
      make_fitment(2021, "Ford", "F-150")
      expect(service.makes(year: 2021)).to eq(["Ford"])
      expect(service.makes(year: nil)).to eq([])
    end
  end

  describe "#models" do
    it "returns models for year+make, case-insensitive on make" do
      make_fitment(2022, "Ford", "Mustang")
      make_fitment(2022, "Ford", "F-150")
      expect(service.models(year: 2022, make: "ford")).to contain_exactly("F-150", "Mustang")
    end
  end

  describe "#trims" do
    it "excludes blank trims" do
      make_fitment(2023, "Ford", "F-150", trim: "Lariat")
      make_fitment(2023, "Ford", "F-150", trim: nil)
      expect(service.trims(year: 2023, make: "Ford", model: "F-150")).to eq(["Lariat"])
    end
  end

  describe "#search_products" do
    it "finds products matching the vehicle and includes universal fits" do
      fitment = make_fitment(2024, "Ford", "F-150")
      universal = make_fitment(2024, "Ford", "F-150", universal: true)

      result = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 50, page: 1)
      expect(result[:product_ids]).to contain_exactly(fitment.product_id, universal.product_id)
      expect(result[:products]).to be_present
    end

    it "returns an empty result when parameters are missing" do
      result = service.search_products(year: nil, make: "Ford", model: "F-150", limit: 50, page: 1)
      expect(result[:product_ids]).to be_empty
    end
  end

  describe ".invalidate_shop_cache" do
    it "bumps the shop version so cached results are rebuilt" do
      make_fitment(2025, "Ford", "F-150")
      expect(service.years).to eq([2025])
      make_fitment(2026, "Ford", "F-150")
      # Without invalidation the cached [2025] would still be served
      described_class.invalidate_shop_cache(shop.id)
      expect(service.years).to eq([2026, 2025])
    end
  end
end
