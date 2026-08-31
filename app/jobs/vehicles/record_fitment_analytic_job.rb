module Vehicles
  # Records a storefront fitment check into daily aggregates. Runs off the
  # request hot path (queued, low priority) so app proxy latency is untouched;
  # loses-on-crash is acceptable for analytics data.
  class RecordFitmentAnalyticJob < ApplicationJob
    queue_as :low_priority

    def perform(shop_id:, metric:, dimension: FitmentAnalytic::DIMENSION_ALL,
                dimension_value: nil, day: Time.zone.today.to_s)
      shop = Shop.find_by(id: shop_id)
      return unless shop

      FitmentAnalytic.increment(shop, metric: metric, dimension: dimension,
                                      dimension_value: dimension_value, day: Date.parse(day))
    end
  end
end
