# Daily aggregate of storefront fitment checks per shop, per dimension
# (all / make / year) and metric (checks / fits / no_fit). Written by a
# background job from counters, so the storefront hot path never writes
# analytics rows synchronously.
class FitmentAnalytic < ApplicationRecord
  include ShopScoped

  METRICS = %w[checks fits no_fit universal].freeze

  validates :metric, inclusion: { in: METRICS }
  validates :day, presence: true
  validates :dimension, presence: true

  scope :for_day, ->(day) { where(day: day) }

  # Increments a metric for a shop/day/dimension atomically.
  def self.increment(shop, metric:, dimension: "all", day: Time.zone.today, by: 1)
    return unless METRICS.include?(metric)

    record = find_or_initialize_by(shop: shop, dimension: dimension, metric: metric, day: day)
    record.with_lock do
      record.value = record.value.to_i + by
      record.save!
    end
  end
end
