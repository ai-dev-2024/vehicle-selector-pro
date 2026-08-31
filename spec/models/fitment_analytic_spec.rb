require "rails_helper"

RSpec.describe FitmentAnalytic, type: :model do
  let(:shop) { create(:shop) }

  describe ".increment" do
    it "sums repeated increments within a day" do
      described_class.increment(shop, metric: "checks", day: Time.zone.today)
      described_class.increment(shop, metric: "checks", day: Time.zone.today)

      row = described_class.find_by(shop: shop, dimension: "all", metric: "checks", day: Time.zone.today)
      expect(row.value).to eq(2)
    end

    it "separates dimension values per make" do
      described_class.increment(shop, metric: "checks", dimension: "make", dimension_value: "Ford", day: Time.zone.today)
      described_class.increment(shop, metric: "checks", dimension: "make", dimension_value: "Toyota", day: Time.zone.today)
      described_class.increment(shop, metric: "checks", dimension: "make", dimension_value: "Ford", day: Time.zone.today)

      expect(described_class.by_make(shop, metric: "checks", from: 30.days.ago, to: Time.zone.today))
        .to contain_exactly({ make: "Ford", value: 2 }, { make: "Toyota", value: 1 })
    end

    it "ignores unknown metrics" do
      expect { described_class.increment(shop, metric: "bogus", day: Time.zone.today) }
        .not_to change(described_class, :count)
    end
  end

  describe ".total" do
    it "sums a dimension-all metric across the day range" do
      described_class.increment(shop, metric: "checks", day: 5.days.ago)
      described_class.increment(shop, metric: "checks", day: 5.days.ago)
      described_class.increment(shop, metric: "fits", day: 5.days.ago)
      described_class.increment(shop, metric: "checks", day: 40.days.ago) # outside range

      expect(described_class.total(shop, "checks", from: 7.days.ago, to: Time.zone.today)).to eq(2)
    end
  end

  describe ".series" do
    it "zero-fills the daily series over the range" do
      described_class.increment(shop, metric: "checks", day: 2.days.ago)
      described_class.increment(shop, metric: "checks", day: 2.days.ago)

      series = described_class.series(shop, "checks", from: 3.days.ago, to: 1.day.ago)
      expect(series.length).to eq(3)
      expect(series[1][:value]).to eq(2)
      expect(series[0][:value]).to eq(0)
      expect(series[2][:value]).to eq(0)
    end
  end

  describe ".by_make" do
    it "respects the day range and ignores dimension-all rows" do
      described_class.increment(shop, metric: "checks", day: 40.days.ago)
      described_class.increment(shop, metric: "checks", dimension: "make", dimension_value: "GMC", day: 40.days.ago)

      result = described_class.by_make(shop, metric: "checks", from: 30.days.ago, to: Time.zone.today)
      expect(result).to be_empty
    end
  end
end
