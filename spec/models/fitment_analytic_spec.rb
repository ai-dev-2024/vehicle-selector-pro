require "rails_helper"

RSpec.describe FitmentAnalytic, type: :model do
  let(:shop) { create(:shop) }

  describe ".increment" do
    it "creates a row on first increment and accumulates on subsequent ones" do
      expect do
        FitmentAnalytic.increment(shop, metric: "checks")
        FitmentAnalytic.increment(shop, metric: "checks")
      end.to change(FitmentAnalytic, :count).by(1)

      expect(FitmentAnalytic.first.value).to eq(2)
    end

    it "rejects unknown metrics" do
      expect(FitmentAnalytic.increment(shop, metric: "bogus")).to be_nil
      expect(FitmentAnalytic.count).to eq(0)
    end
  end
end
