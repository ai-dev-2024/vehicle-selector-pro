module Admin
  # Polaris-style analytics dashboard. Reads the daily fitment_analytics
  # aggregates (written off the storefront hot path) and renders checks,
  # fits, and fit-rate by day and by make for the selected range.
  class AnalyticsController < BaseController
    RANGES = {
      "7d" => 7.days,
      "30d" => 30.days,
      "90d" => 90.days
    }.freeze
    DEFAULT_RANGE = "30d".freeze

    def index
      @range = params[:range].presence_in(RANGES) || DEFAULT_RANGE
      @to = Time.zone.today
      @from = (@to - RANGES.fetch(@range) + 1.day)

      @checks = FitmentAnalytic.total(current_shop, "checks", from: @from, to: @to)
      @fits = FitmentAnalytic.total(current_shop, "fits", from: @from, to: @to)
      @no_fit = FitmentAnalytic.total(current_shop, "no_fit", from: @from, to: @to)
      @universal = FitmentAnalytic.total(current_shop, "universal", from: @from, to: @to)
      @fit_rate = @checks.positive? ? ((@fits.to_f / @checks) * 100).round(1) : 0

      @checks_series = FitmentAnalytic.series(current_shop, "checks", from: @from, to: @to)
      @fits_series = FitmentAnalytic.series(current_shop, "fits", from: @from, to: @to)

      @by_make = FitmentAnalytic.by_make(current_shop, metric: "checks", from: @from, to: @to, count: 12)
      @make_fits = FitmentAnalytic.by_make(current_shop, metric: "fits", from: @from, to: @to, count: 12)
                                  .to_h { |r| [r[:make], r[:value]] }
    end
  end
end
