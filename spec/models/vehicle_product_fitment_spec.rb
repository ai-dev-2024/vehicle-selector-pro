require "rails_helper"

RSpec.describe VehicleProductFitment, type: :model do
  let(:shop) { create(:shop) }
  let(:vehicle) { create(:vehicle) }

  describe "confidence scoring" do
    it "scores direct_fit at 0.9" do
      fitment = create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, fitment_type: "direct_fit")
      expect(fitment.confidence_score.to_f).to eq(0.9)
    end

    it "scores universal at 0.4" do
      fitment = create(:vehicle_product_fitment, shop: shop, universal_fit: true, fitment_type: "universal")
      expect(fitment.confidence_score.to_f).to eq(0.4)
    end

    it "scores modified at 0.5" do
      fitment = create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, fitment_type: "modified")
      expect(fitment.confidence_score.to_f).to eq(0.5)
    end

    it "scores oem at 1.0" do
      fitment = create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, fitment_type: "oem")
      expect(fitment.confidence_score.to_f).to eq(1.0)
    end

    it "exposes confidence in the fitment hash" do
      fitment = create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, fitment_type: "direct_fit")
      expect(fitment.to_fitment_hash[:confidence_score]).to eq(0.9)
    end
  end
end
