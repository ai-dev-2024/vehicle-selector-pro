require "rails_helper"

RSpec.describe Metafields::ProductMetafieldSyncJob, type: :job do
  let(:shop) { create(:shop) }
  let(:product_id) { "gid://shopify/Product/100" }

  def fail_sync_with(error)
    allow(Shopify::MetafieldSyncService).to receive(:sync_product).and_raise(error)
  end

  it "retries when Shopify throttles instead of dropping the sync" do
    fail_sync_with(Shopify::ThrottledError.new("rate limited"))

    expect { described_class.perform_now(shop.id, product_id) }
      .to have_enqueued_job(described_class).with(shop.id, product_id)
  end

  it "retries other sync failures" do
    fail_sync_with(Shopify::GraphQLError.new("HTTP 500"))

    expect { described_class.perform_now(shop.id, product_id) }.to have_enqueued_job(described_class)
  end

  it "discards the job when the shop's token is no longer valid" do
    fail_sync_with(Shopify::AuthenticationError.new("revoked"))

    expect { described_class.perform_now(shop.id, product_id) }.not_to have_enqueued_job(described_class)
  end

  it "skips inactive shops" do
    shop.update!(active: false)
    allow(Shopify::MetafieldSyncService).to receive(:sync_product)

    described_class.perform_now(shop.id, product_id)

    expect(Shopify::MetafieldSyncService).not_to have_received(:sync_product)
  end
end
