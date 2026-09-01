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

    it "prefers the synced Shopify product image over the demo photo map" do
      fitment = make_fitment(2024, "Ford", "F-150")
      fitment.update!(sku: "APX-CAI-F150-EB", category: "Air Intake",
                      product_image: "https://cdn.shopify.com/s/files/1/0000/files/merchant.jpg")
      Rails.cache.clear

      result = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 50, page: 1)
      expect(result[:products].first[:image]).to eq("https://cdn.shopify.com/s/files/1/0000/files/merchant.jpg")
    end

    describe "pagination (DB-level limit/offset)" do
      let(:vehicle) { create(:vehicle, year: 2024, make: "Ford", model: "F-150") }

      # Five specific fitments, distinct product ids, deterministic ordering.
      let!(:fitments) do
        5.times.map do |i|
          create(:vehicle_product_fitment, shop: shop, vehicle: vehicle,
                                           product_id: "gid://shopify/Product/#{100 + i}",
                                           product_title: "Product #{i}")
        end
      end

      it "returns different, non-overlapping pages for page=1 and page=2" do
        page1 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 1)
        page2 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 2)

        expect(page1[:products].pluck(:product_id)).to eq(fitments[0..1].map(&:product_id))
        expect(page2[:products].pluck(:product_id)).to eq(fitments[2..3].map(&:product_id))
        expect(page1[:product_ids]).not_to eq(page2[:product_ids])
        expect(page1[:product_ids] & page2[:product_ids]).to be_empty
      end

      it "keeps product_ids and numeric_product_ids consistent with the paged products" do
        page1 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 1)
        page2 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 2)

        [page1, page2].each do |result|
          expect(result[:products].size).to eq(2)
          expect(result[:product_ids]).to eq(result[:products].map { |p| p[:product_id] })
          expect(result[:numeric_product_ids]).to eq(result[:product_ids].map { |pid| pid.to_s.gsub("gid://shopify/Product/", "") })
        end
      end

      it "reports the full match count as total_count on every page" do
        page1 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 1)
        page2 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 2)
        page3 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 3)

        expect(page1[:total_count]).to eq(5)
        expect(page2[:total_count]).to eq(5)
        # The final page holds the remaining product and reports the same total.
        expect(page3[:total_count]).to eq(5)
        expect(page3[:products].size).to eq(1)
        expect(page3[:product_ids].size).to eq(1)
      end

      it "returns an empty page past the end of the result set" do
        page4 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 4)
        expect(page4[:products]).to be_empty
        expect(page4[:product_ids]).to be_empty
        expect(page4[:numeric_product_ids]).to be_empty
        expect(page4[:total_count]).to eq(5)
      end

      it "dedupes a product that fits multiple matching vehicles (one row per product)" do
        other_trim = create(:vehicle, year: 2024, make: "Ford", model: "F-150", trim: "Lariat")
        # Same product listed for two vehicles of the searched model.
        create(:vehicle_product_fitment, shop: shop, vehicle: other_trim,
                                         product_id: fitments.first.product_id,
                                         product_title: fitments.first.product_title)
        Rails.cache.clear

        page1 = service.search_products(year: 2024, make: "Ford", model: "F-150", limit: 2, page: 1)
        expect(page1[:product_ids].uniq).to eq(page1[:product_ids])
        expect(page1[:product_ids]).to eq(page1[:products].pluck(:product_id))
        expect(page1[:products].pluck(:product_id)).to eq(fitments[0..1].map(&:product_id))
        expect(page1[:total_count]).to eq(5)
      end
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
