require "rails_helper"

RSpec.describe Webhooks::ProductsDeleteJob, type: :job do
  let(:shop) { create(:shop) }

  it "removes the product's fitments in either id form and leaves other products alone" do
    create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/300")
    create(:vehicle_product_fitment, shop: shop, product_id: "300")
    kept = create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/301")

    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 300 })

    expect(shop.vehicle_product_fitments.pluck(:id)).to eq([kept.id])
  end

  # A destroy callback would enqueue a metafield sync for the deleted product.
  it "does not enqueue a metafield sync for the product Shopify just deleted" do
    create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/300")
    sync_calls = 0
    allow(Metafields::ProductMetafieldSyncJob).to(receive(:perform_later) { sync_calls += 1 })

    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 300 })

    expect(sync_calls).to eq(0)
  end

  it "invalidates the storefront cache for the shop" do
    create(:vehicle_product_fitment, shop: shop, product_id: "gid://shopify/Product/300")
    allow(FitmentSearchService).to receive(:invalidate_shop_cache)

    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 300 })

    expect(FitmentSearchService).to have_received(:invalidate_shop_cache).with(shop.id)
  end
end
