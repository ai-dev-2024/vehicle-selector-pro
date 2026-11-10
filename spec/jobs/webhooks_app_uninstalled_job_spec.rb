require "rails_helper"

RSpec.describe Webhooks::AppUninstalledJob, type: :job do
  let(:shop) { create(:shop, billing_plan: "pro", billing_expires_at: 10.days.from_now) }

  # Webhooks::AppUninstalledController enqueues with `shop_domain:` and
  # `webhook:`; the job has to accept exactly those keywords.
  it "deactivates the shop when run with the arguments the controller enqueues" do
    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: { "id" => 1 })

    shop.reload
    expect(shop.active).to be(false)
    expect(shop.uninstalled_at).to be_present
    expect(shop.shopify_token).to start_with("revoked_")
  end

  it "drops the shop back to the free plan so a reinstall does not inherit paid limits" do
    described_class.perform_now(shop_domain: shop.shopify_domain, webhook: {})

    shop.reload
    expect(shop.billing_plan).to eq("free")
    expect(shop.billing_expires_at).to be_nil
  end

  it "ignores an unknown shop" do
    expect { described_class.perform_now(shop_domain: "ghost.myshopify.com", webhook: {}) }
      .not_to change(Shop.active, :count)
  end
end
