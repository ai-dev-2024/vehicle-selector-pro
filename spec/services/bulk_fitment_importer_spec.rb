require "rails_helper"

RSpec.describe BulkFitmentImporter do
  let(:shop) { create(:shop) }

  it "imports specific and universal rows and enqueues sync for affected products" do
    csv = <<~CSV
      product_id,product_handle,product_title,year,make,model,trim,engine,universal,notes
      1001,cold-air-intake,Cold Air Intake,2024,Ford,F-150,Lariat,3.5L EcoBoost,false,Direct fit
      1002,universal-floor-mats,Rubber Floor Mats,,,,,,true,Universal fit
    CSV

    result = described_class.new(shop, csv).import!

    expect(result[:success_count]).to eq(2)
    expect(result[:error_count]).to eq(0)
    expect(Vehicle.find_by(year: 2024, make: "Ford", model: "F-150", trim: "Lariat")).to be_present
    expect(shop.vehicle_product_fitments.universal.count).to eq(1)
    expect(Metafields::BatchSyncJob).to have_received(:perform_later)
  end

  it "reports rows missing required vehicle fields" do
    csv = <<~CSV
      product_id,year,make,model
      1001,,,
    CSV

    result = described_class.new(shop, csv).import!
    expect(result[:error_count]).to eq(1)
    expect(result[:errors].first).to include("Year, Make, and Model")
  end

  it "rejects CSVs with no recognizable product or vehicle columns" do
    result = described_class.new(shop, "a,b\n1,2\n").import!
    expect(result[:errors].first).to include("CSV must contain at least one of")
    expect(result[:success_count]).to eq(0)
  end

  it "is idempotent — re-importing the same CSV does not duplicate records" do
    csv = <<~CSV
      product_id,year,make,model
      1001,2024,Ford,F-150
    CSV

    described_class.new(shop, csv).import!
    result = described_class.new(shop, csv).import!

    expect(result[:success_count]).to eq(1)
    expect(shop.vehicle_product_fitments.count).to eq(1)
  end
end
