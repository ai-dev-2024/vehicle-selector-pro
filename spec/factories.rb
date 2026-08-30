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
end
