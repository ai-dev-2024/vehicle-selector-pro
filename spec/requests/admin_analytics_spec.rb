require "rails_helper"

RSpec.describe "Admin analytics", type: :request do
  let(:shop) { create(:shop) }

  before { authenticate_admin!(shop) }

  describe "GET /admin/analytics" do
    it "renders the dashboard with empty-state metrics" do
      get admin_analytics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Storefront analytics")
      expect(response.body).to include("Fitment checks")
    end

    it "shows daily aggregates for the current shop" do
      FitmentAnalytic.increment(shop, metric: "checks", day: 2.days.ago)
      FitmentAnalytic.increment(shop, metric: "checks", day: 2.days.ago)
      FitmentAnalytic.increment(shop, metric: "fits", day: 2.days.ago)
      FitmentAnalytic.increment(shop, metric: "no_fit", day: Time.zone.today)

      get admin_analytics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("3") # total checks
      expect(response.body).to include("Checks by make")
    end

    it "breaks out fits by make when make dimensions are recorded" do
      FitmentAnalytic.increment(shop, metric: "checks", dimension: "make", dimension_value: "Ford", day: Time.zone.today)
      FitmentAnalytic.increment(shop, metric: "fits", dimension: "make", dimension_value: "Ford", day: Time.zone.today)
      FitmentAnalytic.increment(shop, metric: "checks", dimension: "make", dimension_value: "Toyota", day: Time.zone.today)

      get admin_analytics_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Ford")
      expect(response.body).to include("Toyota")
    end

    it "isolates analytics to the current shop" do
      other = create(:shop)
      FitmentAnalytic.increment(other, metric: "checks", day: Time.zone.today)

      get admin_analytics_path
      expect(response.body).not_to include("1\n") # other shop's single check is not shown
    end

    it "validates the range param" do
      get admin_analytics_path(range: "bogus")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("30d view")
    end
  end
end
