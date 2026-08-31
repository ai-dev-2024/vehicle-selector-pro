require "rails_helper"

RSpec.describe Metafields::ProductBackfillJob, type: :job do
  let(:shop) { create(:shop) }

  def make_log
    MetafieldSyncLog.create!(shop: shop, sync_type: "backfill", status: "pending")
  end

  it "runs the backfill service and records a completed log" do
    log = make_log
    report = { products: 5, fitments_updated: 12, errors: [] }
    service = instance_double(Shopify::ProductBackfillService, run: report)
    allow(Shopify::ProductBackfillService).to receive(:new).and_return(service)

    described_class.perform_now(shop.id, log.id)

    expect(service).to have_received(:run)
    log.reload
    expect(log.status).to eq("completed")
    expect(log.synced_products).to eq(12)
    expect(log.total_products).to eq(5)
  end

  it "does nothing for an unknown shop" do
    expect { described_class.perform_now(999_999, nil) }.not_to raise_error
  end

  it "flags the log on failure" do
    log = make_log
    allow(Shopify::ProductBackfillService).to receive(:new).and_raise("boom")

    begin
      described_class.perform_now(shop.id, log.id)
    rescue StandardError
      # the job marks the log failed, then re-raises; we assert the log state
    end
    expect(log.reload.status).to eq("failed")
    expect(log.reload.error_details).to include("boom")
  end
end
