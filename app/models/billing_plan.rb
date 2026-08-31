# Plan catalogue for Shopify Billing. Plans are stored as a plain string on
# the shop (shops.billing_plan) — no dedicated table needed, since the source
# of truth is Shopify's active subscriptions; this file maps a plan key to its
# billing params and feature limits.
#
# Limits are enforced where they make sense today (bulk import size); extend
# this module as more features become tier-gated.
class BillingPlan
  include ActiveSupport::Configurable

  FREE = "free".freeze
  PRO = "pro".freeze
  PLUS = "plus".freeze
  DEFAULT = FREE

  # name:        merchant-visible tier name
  # price:       monthly recurring price (USD)
  # trial_days:  free trial length; 0 = none
  # chart_name:  the Shopify subscription charge name (used for matching
  #              activeSubscriptions in the Billing API)
  # max_fitments: ceiling for the bulk CSV import (rows of fitment mappings)
  PLANS = {
    FREE => {
      name: "Free",
      price: 0,
      trial_days: 0,
      chart_name: "Vehicle Selector Pro — Free",
      max_fitments: 500
    },
    PRO => {
      name: "Pro",
      price: 9.99,
      trial_days: 14,
      chart_name: "Vehicle Selector Pro — Pro",
      max_fitments: 5_000
    },
    PLUS => {
      name: "Pro Plus",
      price: 29.99,
      trial_days: 14,
      chart_name: "Vehicle Selector Pro — Pro Plus",
      max_fitments: 100_000
    }
  }.freeze

  def self.all
    PLANS.map { |key, attrs| new(key, attrs) }
  end

  def self.find(key)
    key = key.to_s
    attrs = PLANS[key] or return nil
    new(key, attrs)
  end

  def self.default
    find(DEFAULT)
  end

  attr_reader :key, :name, :price, :trial_days, :chart_name, :max_fitments

  def initialize(key, attrs)
    @key = key.to_s
    @name = attrs[:name]
    @price = attrs[:price]
    @trial_days = attrs[:trial_days]
    @chart_name = attrs[:chart_name]
    @max_fitments = attrs[:max_fitments]
  end

  def free?
    key == FREE
  end

  def monthly_price_s
    return "$0" if price.to_f.zero?

    format("$%.2f/mo", price)
  end
end
