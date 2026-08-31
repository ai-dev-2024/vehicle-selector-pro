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

  describe "cascading filter options" do
    it "returns distinct values per level, ordered and shop-scoped" do
      make_fitment(2021, "Ford", "F-150", trim: "Lariat", engine: "3.5L")
      make_fitment(2020, "Ford", "F-150", trim: "XLT", engine: "2.7L")
      make_fitment(2020, "Ford", "F-150", trim: "Lariat", engine: "3.5L")
      make_fitment(2020, "Toyota", "Tacoma", trim: "TRD", engine: "3.5L")
      other = create(:shop)
      create(:vehicle_product_fitment, shop: other,
                                       vehicle: create(:vehicle, year: 1999, make: "Dodge", model: "Ram"))

      expect(service.years).to eq([2021, 2020])
      expect(service.makes(year: 2021)).to eq(["Ford"])
      expect(service.makes(year: 2020)).to contain_exactly("Ford", "Toyota")
      # make matching is case-insensitive
      expect(service.models(year: 2020, make: "ford")).to contain_exactly("F-150")
      expect(service.trims(year: 2020, make: "Ford", model: "F-150")).to contain_exactly("XLT", "Lariat")
      expect(service.engines(year: 2020, make: "Ford", model: "F-150")).to contain_exactly("2.7L", "3.5L")
    end

    it "excludes blank trims and engines" do
      make_fitment(2020, "Ford", "F-150", trim: nil, engine: nil)
      expect(service.trims(year: 2020, make: "Ford", model: "F-150")).to eq([])
      expect(service.engines(year: 2020, make: "Ford", model: "F-150")).to eq([])
    end

    it "returns [] when a required filter is missing" do
      expect(service.makes(year: nil)).to eq([])
      expect(service.models(year: 2020, make: nil)).to eq([])
      expect(service.trims(year: 2020, make: "Ford", model: nil)).to eq([])
      expect(service.engines(year: 2020, make: "Ford", model: nil)).to eq([])
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
