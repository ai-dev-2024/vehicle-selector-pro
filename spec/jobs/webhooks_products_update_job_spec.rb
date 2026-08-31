require "rails_helper"

RSpec.describe Webhooks::ProductsUpdateJob, type: :job do
  include ActiveJob::TestHelper

  let(:shop) { create(:shop) }
  let(:vehicle) { create(:vehicle, year: 2021, make: "Ford", model: "F-150") }
  let!(:fitment) do
    create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, product_id: "gid://shopify/Product/100",
                                     product_title: "Old Title")
  end

  it "updates cached product metadata on matching fitments" do
    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 100, "title" => "New Title" })
    expect(fitment.reload.product_title).to eq("New Title")
  end

  it "syncs the merchant's product photo from the webhook payload" do
    webhook = {
      "id" => 100,
      "image" => { "src" => "https://cdn.shopify.com/s/files/1/0000/files/intake.jpg?v=1" },
      "images" => [{ "src" => "https://cdn.shopify.com/s/files/1/0000/files/alt.jpg" }]
    }

    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: webhook)
    expect(fitment.reload.product_image).to eq("https://cdn.shopify.com/s/files/1/0000/files/intake.jpg?v=1")
  end

  it "falls back to the first image when the payload has no primary image" do
    described_class.perform_now(
      shop_domain: shop.shopify_domain,
      webhook: { "id" => 100, "images" => [{ "src" => "https://cdn.shopify.com/s/files/1/0000/files/alt.jpg" }] }
    )
    expect(fitment.reload.product_image).to eq("https://cdn.shopify.com/s/files/1/0000/files/alt.jpg")
  end

  it "does nothing when the shop is unknown" do
    expect do
      described_class.perform_now(shop_domain: "ghost.myshopify.com", webhook: { "id" => 100 })
    end.not_to(change { fitment.reload.product_title })
  end

  it "does nothing when the shop is uninstalled, and logs the drop" do
    shop.mark_as_uninstalled!
    allow(Rails.logger).to receive(:warn).and_call_original
    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 100 })
    expect(Rails.logger).to have_received(:warn).with(%r{Dropped webhook for missing/inactive shop})
  end
end
