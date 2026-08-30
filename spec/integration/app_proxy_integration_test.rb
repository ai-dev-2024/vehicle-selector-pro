# Integration tests for the storefront App Proxy endpoints.
#
# Unlike the isolated unit harness in spec/test_runner.rb (which fakes Rails),
# this file boots the real Rails application and issues actual HTTP requests
# through the full middleware stack, verifying routing, HMAC shop resolution,
# the FitmentSearchService, and JSON responses end to end.
#
# Run with:  ruby spec/integration/app_proxy_integration_test.rb
ENV["RAILS_ENV"] ||= "test"
require_relative "../../config/environment"
require "rails/test_help"
require "minitest/autorun"

class AppProxyIntegrationTest < ActionDispatch::IntegrationTest
  # The App Proxy base controller permits a simulated signature in the test
  # environment, so we sign every request with this sentinel value.
  TEST_SIG = "test_valid_signature".freeze

  setup do
    # Fresh, deterministic data for each test.
    VehicleProductFitment.delete_all
    MetafieldSyncLog.delete_all
    AppSetting.delete_all
    Vehicle.delete_all
    Shop.delete_all
    Rails.cache.clear

    @shop = Shop.create!(
      shopify_domain: "integration-test.myshopify.com",
      shopify_token: "test-token",
      name: "Integration Test Store",
      active: true
    )

    @vehicle = Vehicle.create!(
      year: 2024, make: "Ford", model: "F-150",
      trim: "Lariat", engine: "3.5L EcoBoost V6"
    )

    @fitment = VehicleProductFitment.create!(
      shop: @shop,
      vehicle: @vehicle,
      product_id: "gid://shopify/Product/999000111",
      product_handle: "test-intake",
      product_title: "Test Cold Air Intake",
      sku: "TST-CAI-001",
      universal_fit: false,
      fitment_type: "direct_fit"
    )
  end

  def proxy_get(path, params = {})
    get "/apps/vehicle-selector/#{path}",
        params: params.merge(signature: TEST_SIG, shop: @shop.shopify_domain)
  end

  test "years endpoint returns distinct catalog years" do
    proxy_get "years"
    assert_response :success
    body = JSON.parse(response.body)
    assert body["success"]
    assert_includes body["years"], 2024
  end

  test "cascading makes/models/trims/engines resolve" do
    proxy_get "makes", year: 2024
    assert_includes JSON.parse(response.body)["makes"], "Ford"

    proxy_get "models", year: 2024, make: "Ford"
    assert_includes JSON.parse(response.body)["models"], "F-150"

    proxy_get "trims", year: 2024, make: "Ford", model: "F-150"
    assert_includes JSON.parse(response.body)["trims"], "Lariat"

    proxy_get "engines", year: 2024, make: "Ford", model: "F-150"
    assert_includes JSON.parse(response.body)["engines"], "3.5L EcoBoost V6"
  end

  test "search returns matching product ids for a vehicle" do
    proxy_get "search", year: 2024, make: "Ford", model: "F-150"
    assert_response :success
    data = JSON.parse(response.body)["data"]
    assert_includes data["product_ids"], "gid://shopify/Product/999000111"
    assert data["total_count"] >= 1
  end

  test "check_fitment resolves a NUMERIC product id (regression)" do
    # Regression: previously only the GID form matched, so a numeric id
    # (what Liquid product.id provides) incorrectly returned fits=false.
    proxy_get "check_fitment",
              product_id: "999000111", year: 2024, make: "Ford", model: "F-150"
    assert_response :success
    data = JSON.parse(response.body)["data"]
    assert data["fits"], "numeric product id should resolve to a fit, got: #{data.inspect}"
    assert_equal "direct_fit", data["fitment_type"]
  end

  test "check_fitment resolves a GID product id" do
    proxy_get "check_fitment",
              product_id: "gid://shopify/Product/999000111",
              year: 2024, make: "Ford", model: "F-150"
    data = JSON.parse(response.body)["data"]
    assert data["fits"], "GID product id should resolve to a fit, got: #{data.inspect}"
  end

  test "check_fitment reports non-fit for an unrelated vehicle" do
    proxy_get "check_fitment",
              product_id: "999000111", year: 1999, make: "Honda", model: "Civic"
    data = JSON.parse(response.body)["data"]
    refute data["fits"]
  end

  test "product_fitments resolves numeric product id (regression)" do
    proxy_get "product_fitments", product_id: "999000111"
    assert_response :success
    body = JSON.parse(response.body)
    assert body["fitments"].any?, "expected fitments for numeric id, got: #{body.inspect}"
    assert_equal "gid://shopify/Product/999000111", body["fitments"].first["product_id"]
  end

  test "unsigned requests are rejected" do
    # No signature param at all -> HMAC verification must fail.
    get "/apps/vehicle-selector/years"
    assert_response :unauthorized
  end

  test "search pagination returns disjoint pages with the full id list" do
    5.times do |i|
      VehicleProductFitment.create!(
        shop: @shop,
        vehicle: @vehicle,
        product_id: "gid://shopify/Product/#{999_100 + i}",
        product_handle: "p#{i}",
        product_title: "Product #{i}",
        sku: "SKU-#{i}",
        universal_fit: false,
        fitment_type: "direct_fit"
      )
    end

    proxy_get "search", year: 2024, make: "Ford", model: "F-150", limit: 2, page: 1
    page1 = JSON.parse(response.body)["data"]
    proxy_get "search", year: 2024, make: "Ford", model: "F-150", limit: 2, page: 2
    page2 = JSON.parse(response.body)["data"]

    # 5 new fitments + the setup fitment = 6 matching products.
    assert_equal 6, page1["total_count"]
    assert_equal 6, page1["product_ids"].size, "product_ids should list every match, not just the page"
    assert_equal page1["product_ids"], page1["product_ids"].sort, "product_ids must be deterministically ordered"
    assert_equal 2, page1["products"].size
    assert_equal 2, page2["products"].size
    ids1 = page1["products"].map { |p| p["product_id"] } # rubocop:disable Rails/Pluck -- plain hashes, not AR
    ids2 = page2["products"].map { |p| p["product_id"] } # rubocop:disable Rails/Pluck -- plain hashes, not AR
    assert_empty ids1 & ids2, "page 1 and page 2 must not overlap"
  end

  test "shop/redact webhook erases all shop-scoped data" do
    post "/webhooks/shop_redact", params: {}.to_json,
                                  headers: {
                                    "CONTENT_TYPE" => "application/json",
                                    "X-Shopify-Shop-Domain" => @shop.shopify_domain
                                  }
    assert_response :ok
    assert_nil Shop.find_by(shopify_domain: @shop.shopify_domain),
               "shop row must be erased on shop/redact"
    assert_equal 0, VehicleProductFitment.count,
                 "fitments must be erased with the shop"
    assert_equal 0, MetafieldSyncLog.count
    assert_equal 0, AppSetting.count
  end

  test "customers/data_request webhook is acknowledged without touching data" do
    post "/webhooks/customers_data_request",
         params: { customer: { id: 123 } }.to_json,
         headers: {
           "CONTENT_TYPE" => "application/json",
           "X-Shopify-Shop-Domain" => @shop.shopify_domain
         }
    assert_response :ok
    assert_equal 1, VehicleProductFitment.count, "data_request is a read-only acknowledgement"
  end

  test "products/update webhook is handled by the app controller and enqueued" do
    # Regression: the ShopifyApp engine's catch-all /webhooks/(:type) route used
    # to intercept this and raise NoWebhookHandler (HTTP 500). The engine is now
    # mounted after the app routes so this reaches our controller. (HMAC
    # verification is intentionally skipped in the test environment.)
    assert_enqueued_with(job: Webhooks::ProductsUpdateJob) do
      post "/webhooks/products_update",
           params: { id: 42, title: "Webhook Test", handle: "webhook-test" }.to_json,
           headers: {
             "CONTENT_TYPE" => "application/json",
             "X-Shopify-Topic" => "products/update",
             "X-Shopify-Shop-Domain" => @shop.shopify_domain
           }
    end
    assert_response :ok
  end
end
