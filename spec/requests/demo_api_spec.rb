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
end
