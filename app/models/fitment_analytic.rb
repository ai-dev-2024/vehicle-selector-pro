# Daily aggregate of storefront fitment checks per shop, per dimension
# (all / make / year) and metric (checks / fits / no_fit / universal),
# optionally broken out by a value (e.g. the make name). Written by a
# background job from counters, so the storefront hot path never writes
# analytics rows synchronously.
class FitmentAnalytic < ApplicationRecord
  include ShopScoped

  METRICS = %w[checks fits no_fit universal].freeze

  validates :metric, inclusion: { in: METRICS }
  validates :day, presence: true
  validates :dimension, presence: true

  scope :for_day, ->(day) { where(day: day) }
  scope :between_days, ->(from, to) { where(day: from..to) }
  scope :with_metric, ->(*metrics) { where(metric: metrics) }
  scope :dimension_all, -> { where(dimension: DIMENSION_ALL) }
  scope :dimension_make, -> { where(dimension: DIMENSION_MAKE) }

  DIMENSION_ALL = "all".freeze
  DIMENSION_MAKE = "make".freeze

  # Increments a metric for a shop/day/dimension (+ optional value) atomically.
  def self.increment(shop, metric:, dimension: DIMENSION_ALL, dimension_value: nil, day: Time.zone.today, by: 1)
    return unless METRICS.include?(metric)

    record = find_or_initialize_by(shop: shop, dimension: dimension, dimension_value: dimension_value,
                                   metric: metric, day: day)
    record.with_lock do
      record.value = record.value.to_i + by
      record.save!
    end
  end

  # Sum of a metric across the given shop for the requested day range.
  def self.total(shop, metric, from:, to: Time.zone.today)
    for_shop(shop).dimension_all.with_metric(metric).between_days(*range_bounds(from, to)).sum(:value)
  end

  # Daily [{ date, value }] series (zero-filled) for a metric over a day range.
  def self.series(shop, metric, from:, to: Time.zone.today)
    from, to = range_bounds(from, to)
    rows = for_shop(shop).dimension_all.with_metric(metric)
                         .between_days(from, to).group(:day).sum(:value)

    (from..to).map do |day|
      { date: day, value: rows.fetch(day, 0) }
    end
  end

  # Per-make breakdown [{ make, checks }] within a day range, sorted by check
  # volume descending.
  def self.by_make(shop, metric:, from:, to: Time.zone.today, count: 10)
    from, to = range_bounds(from, to)
    checks = for_shop(shop).where(dimension: DIMENSION_MAKE)
                           .with_metric(metric).between_days(from, to)
                           .group(:dimension_value).sum(:value)

    rows = checks.filter_map do |value, count_value|
      next if value.blank?

      { make: value, value: count_value.to_i }
    end
    rows.sort_by { |r| -r[:value] }.first(count)
  end

  # Normalizes the from/to day-range arguments to Date objects so callers can
  # pass either dates or durations (e.g. `Time.zone.today - 30.days`).
  def self.range_bounds(from, to)
    [from.to_date, to.to_date]
  end
  private_class_method :range_bounds
end
