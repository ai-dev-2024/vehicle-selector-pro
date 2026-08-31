FactoryBot.define do
  factory :shop do
    sequence(:shopify_domain) { |n| "shop-#{n}.myshopify.com" }
    shopify_token { SecureRandom.hex(16) }
    name { "Test Shop" }
    active { true }
  end

  factory :vehicle do
    sequence(:year) { |n| 2010 + (n % 15) }
    make { "Ford" }
    sequence(:model) { |n| "F-150-#{n}" }
    trim { nil }
    engine { nil }
  end

  factory :vehicle_product_fitment, class: "VehicleProductFitment" do
    association :shop
    association :vehicle

    transient do
      product_id_value { nil }
    end

    product_id { product_id_value || "gid://shopify/Product/#{rand(1_000_000)}" }
    universal_fit { false }
    fitment_type { "direct_fit" }
    synced_to_metafield { false }
  end

  trait :universal do
    vehicle { nil }
    universal_fit { true }
    fitment_type { "universal" }
  end

  factory :oe_number do
    association :shop
    product_id { "gid://shopify/Product/#{rand(1_000_000)}" }
    sequence(:oe_number) { |n| "OE-#{n}-#{SecureRandom.hex(4).upcase}" }
  end

  factory :webhook_delivery do
    shop_domain { "shop-1.myshopify.com" }
    topic { "products/update" }
    sequence(:webhook_id) { |n| "wh-#{n}" }
    processed_at { Time.current }
  end

  factory :fitment_analytic do
    association :shop
    dimension { "all" }
    metric { "checks" }
    value { 1 }
    day { Time.zone.today }
  end
end
