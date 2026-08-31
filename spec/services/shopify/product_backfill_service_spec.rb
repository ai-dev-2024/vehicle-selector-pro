require "rails_helper"

RSpec.describe Shopify::ProductBackfillService do
  let(:shop) { create(:shop) }

  before do
    @client = instance_double(Shopify::GraphQLClient)
    allow(Shopify::GraphQLClient).to receive(:new).and_return(@client)
  end

  def page(products, has_next: false, cursor: nil)
    {
      "products" => {
        "pageInfo" => { "hasNextPage" => has_next, "endCursor" => cursor },
        "edges" => products
      }
    }
  end

  it "pages through the shop's products and refreshes mapped fitments" do
    f1 = create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/1",
                                          product_title: "Old", product_handle: nil, product_image: nil)
    create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/2", product_title: nil)

    allow(@client).to receive(:query).with(anything, { "cursor" => nil }).and_return(
      page([{ "node" => { "id" => "gid://shopify/Product/1", "title" => "New Title", "handle" => "new-handle",
                          "featuredImage" => { "url" => "https://cdn/x.jpg" } } }],
           has_next: true, cursor: "c1")
    )
    allow(@client).to receive(:query).with(anything, { "cursor" => "c1" }).and_return(
      page([{ "node" => { "id" => "gid://shopify/Product/2", "title" => "Second" } }])
    )

    report = described_class.new(shop).run

    expect(report[:products]).to eq(2)
    expect(report[:errors]).to be_empty
    expect(f1.reload.product_title).to eq("New Title")
    expect(f1.reload.product_handle).to eq("new-handle")
    expect(f1.reload.product_image).to eq("https://cdn/x.jpg")
  end

  it "never blanks a field Shopify omitted" do
    f = create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/1",
                                         product_title: "Keep Me", product_image: "https://cdn/keep.jpg")
    allow(@client).to receive(:query).and_return(
      page([{ "node" => { "id" => "gid://shopify/Product/1", "title" => "New" } }])
    )

    described_class.new(shop).run

    expect(f.reload.product_title).to eq("New")
    expect(f.reload.product_image).to eq("https://cdn/keep.jpg") # image not in payload -> untouched
  end

  it "records a top-level query failure in the report instead of raising" do
    allow(@client).to receive(:query).and_raise(Shopify::GraphQLError, "rate limit / nope")

    report = described_class.new(shop).run

    expect(report[:products]).to eq(0)
    expect(report[:errors]).to include(/Query failed.*nope/)
  end

  it "accepts a shop domain string" do
    allow(@client).to receive(:query).and_return(page([]))
    expect { described_class.new(shop.shopify_domain).run }.not_to raise_error
  end
end
