ShopifyApp.configure do |config|
  config.application_name = "Vehicle Selector Pro"
  config.old_secret = ""
  config.scope = "read_products,write_products,read_product_listings,read_customers,write_customers" # Scopes for managing vehicle fitment metafields
  config.embedded_app = true
  config.after_authenticate_job = false
  config.api_version = "2025-07"
  config.shop_session_repository = 'Shop'
  config.log_level = :info
  config.reauth_on_access_scope_changes = true

  # Webhooks configuration
  config.webhooks = [
    { topic: 'products/create', address: '/webhooks/products_create' },
    { topic: 'products/update', address: '/webhooks/products_update' },
    { topic: 'products/delete', address: '/webhooks/products_delete' },
    { topic: 'app/uninstalled', address: '/webhooks/app_uninstalled' },
    { topic: 'shop/update', address: '/webhooks/shop_update' },
    { topic: 'customers/data_request', address: '/webhooks/customers_data_request' },
    { topic: 'customers/redact', address: '/webhooks/customers_redact' },
    { topic: 'shop/redact', address: '/webhooks/shop_redact' }
  ]

  # App Proxy Configuration
  config.api_key = ENV.fetch('SHOPIFY_API_KEY') { Rails.application.credentials.dig(:shopify, :api_key) || raise('SHOPIFY_API_KEY missing') }
  config.secret = ENV.fetch('SHOPIFY_API_SECRET') { Rails.application.credentials.dig(:shopify, :api_secret) || raise('SHOPIFY_API_SECRET missing') }
end
