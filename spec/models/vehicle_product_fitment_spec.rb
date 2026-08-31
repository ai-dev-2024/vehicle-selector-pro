require "rails_helper"

RSpec.describe VehicleProductFitment, type: :model do
  let(:shop) { create(:shop) }
  let(:vehicle) { create(:vehicle) }

  it "requires a vehicle unless the fitment is universal" do
    fitment = described_class.new(shop: shop, product_id: "p1", universal_fit: false)
    expect(fitment).not_to be_valid
    expect(fitment.errors[:vehicle]).to be_present

    fitment.universal_fit = true
    expect(fitment).to be_valid
  end

  describe "uniqueness" do
    it "allows one product+vehicle pairing per shop, but the same pair under another shop" do
      create(:vehicle_product_fitment, shop: shop, vehicle: vehicle, product_id: "p1")

      duplicate = build(:vehicle_product_fitment, shop: shop, vehicle: vehicle, product_id: "p1")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:vehicle_id]).to be_present

      other_shop = create(:shop)
      expect(build(:vehicle_product_fitment, shop: other_shop, vehicle: vehicle, product_id: "p1")).to be_valid
    end

    it "allows only one universal fitment per product per shop" do
      create(:vehicle_product_fitment, :universal, shop: shop, product_id: "p1")
      duplicate = build(:vehicle_product_fitment, :universal, shop: shop, product_id: "p1")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end
  end
end
