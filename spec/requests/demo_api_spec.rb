require "rails_helper"

RSpec.describe "Demo API product pagination", type: :request do
  let(:shop) { create(:shop) }

  before do
    allow(DemoShopResolver).to receive(:resolve).and_return(shop)
    30.times do |i|
      create(:vehicle_product_fitment, shop: shop, sku: "APX-POD-#{format('%03d', i)}",
                                       category: "Lighting", product_title: "Part #{i}",
                                       price_cents: 1000 + i)
    end
  end

  def products_for(path)
    get path
    expect(response).to have_http_status(:ok)
    response.parsed_body
  end

  it "paginates the full catalog page by page until has_more is false" do
    page1 = products_for("/demo/api/products?page=1&limit=24")
    expect(page1["success"]).to be true
    expect(page1["products"].size).to eq(24)
    expect(page1["total"]).to eq(30)
    expect(page1["has_more"]).to be true

    page2 = products_for("/demo/api/products?page=2&limit=24")
    expect(page2["products"].size).to eq(6)
    expect(page2["has_more"]).to be false

    ids1 = page1["products"].pluck("product_id")
    ids2 = page2["products"].pluck("product_id")
    expect(ids1 & ids2).to be_empty
  end

  it "filters the page set by category" do
    create(:vehicle_product_fitment, shop: shop, sku: "APX-EXH", category: "Exhaust",
                                     product_title: "Cat-back")
    all = products_for("/demo/api/products?page=1&limit=50")
    expect(all["total"]).to eq(31)

    exhaust = products_for("/demo/api/products?page=1&limit=50&category=Exhaust")
    expect(exhaust["total"]).to eq(1)
    expect(exhaust["products"].first["category"]).to eq("Exhaust")
  end

  it "returns a card-shaped payload (title, image, price) for the client renderer" do
    body = products_for("/demo/api/products?page=1&limit=1")
    card = body["products"].first
    expect(card).to include("product_id", "title", "sku", "brand", "category", "price_cents", "image")
    expect(card["title"]).to be_present
  end

  it "searches by a year|make|model token for a filtered vehicle" do
    vehicle = create(:vehicle, year: 2024, make: "Ford", model: "F-150")
    create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, sku: "APX-CAI", product_title: "Intake")

    body = products_for("/demo/api/products?page=1&limit=24&token=2024%7CFord%7CF-150")
    expect(body["total"]).to eq(1)
    expect(body["products"].first["sku"]).to eq("APX-CAI")
  end

  it "featured=1 returns exactly the curated bestsellers in curated order" do
    # The curated order must survive the response: the shop page grid is a
    # hand-picked storefront, so sorting by DB scan order would reshuffle it.
    DemoCatalog::FEATURED_SKUS.each_with_index do |sku, i|
      create(:vehicle_product_fitment, shop: shop, sku: sku, category: "Part #{i}",
                                       product_title: "Curated #{i}", price_cents: 1000 + i)
    end
    # A non-curated product in the catalog must never leak into the featured grid.
    create(:vehicle_product_fitment, shop: shop, sku: "APX-POD-999", category: "Lighting",
                                     product_title: "Not featured")

    body = products_for("/demo/api/products?page=1&limit=100&featured=1")
    expect(body["total"]).to eq(DemoCatalog::FEATURED_SKUS.size)
    expect(body["has_more"]).to be false
    expect(body["products"].pluck("sku")).to eq(DemoCatalog::FEATURED_SKUS)
  end
end

# /demo and /demo/api are public and unauthenticated, so the shop behind them
# must never be a real tenant.
RSpec.describe "Public demo tenant isolation", type: :request do
  # The test database can already hold the real demo-domain shop: CI runs
  # db:prepare, which seeds a fresh database. Point the resolver at a domain
  # nothing else creates, so these examples control whether the demo shop
  # exists instead of depending on the seeds.
  let(:demo_domain) { "demo-shop-under-test.example" }
  let!(:merchant) { create(:shop, name: "Private Merchant Parts") }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("SHOPIFY_STORE_DOMAIN", anything).and_return(demo_domain)
    create(:vehicle_product_fitment, shop: merchant, product_title: "Private Merchant Part")
  end

  it "resolves the demo-domain shop even when another shop has more data" do
    demo = create(:shop, shopify_domain: demo_domain)
    expect(DemoShopResolver.resolve).to eq(demo)
  end

  it "falls back to some existing shop in local development when the demo shop is missing" do
    resolved = DemoShopResolver.resolve

    expect(resolved).to be_a(Shop)
    expect(resolved.shopify_domain).not_to eq(demo_domain)
  end

  context "outside local development" do
    before { allow(Rails.env).to receive(:local?).and_return(false) }

    it "does not fall back to another tenant when the demo shop is missing" do
      expect(Shop.count).to be >= 1
      expect(DemoShopResolver.resolve).to be_nil
    end

    it "serves the demo shop, and only the demo shop, when it exists" do
      demo = create(:shop, shopify_domain: demo_domain)
      create(:vehicle_product_fitment, shop: demo, product_title: "Demo Catalog Part")

      get "/demo/api/products?page=1&limit=100"

      expect(response).to have_http_status(:ok)
      titles = response.parsed_body["products"].pluck("title")
      expect(titles).to eq(["Demo Catalog Part"])
    end

    it "makes the demo API unavailable instead of serving a merchant's catalog" do
      get "/demo/api/products?page=1&limit=10"

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).not_to include("Private Merchant Part")
    end

    it "makes the demo admin unavailable instead of rendering a merchant's dashboard" do
      get "/demo/admin"

      expect(response).to have_http_status(:service_unavailable)
      expect(response.body).not_to include("Private Merchant Parts")
    end
  end
end
