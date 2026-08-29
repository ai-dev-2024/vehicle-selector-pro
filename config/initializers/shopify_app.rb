ShopifyApp.configure do |config|
  config.application_name = "Vehicle Selector Pro"
  config.old_secret = ""
  config.scope = "read_products,write_products,read_product_listings" # Scopes for managing vehicle fitment metafields
  config.embedded_app = true
  config.after_authenticate_job = false
  config.api_version = "2024-04"
  config.shop_session_repository = 'Shop'
  config.log_level = :info
  config.reauth_on_access_scope_changes = true

  # Webhooks configuration
  config.webhooks = [
    { topic: 'products/create', address: 'webhooks/products_create' },
    { topic: 'products/update', address: 'webhooks/products_update' },
    { topic: 'products/delete', address: 'webhooks/products_delete' },
    { topic: 'app/uninstalled', address: 'webhooks/app_uninstalled' },
    { topic: 'shop/update', address: 'webhooks/shop_update' }
  ]

  # App Proxy Configuration
  config.api_key = ENV.fetch('SHOPIFY_API_KEY', 'vsp_test_api_key')
  config.secret = ENV.fetch('SHOPIFY_API_SECRET', 'vsp_test_api_secret_4493019349810')
end

ShopifyApp::SessionRepository.shop_storage = Shop
