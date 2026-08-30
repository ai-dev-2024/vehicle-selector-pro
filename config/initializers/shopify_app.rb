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
  # Note: the mandatory customer-privacy webhooks (customers/data_request,
  # customers/redact, shop/redact) cannot be registered via the API — they
  # are configured in the Partners Dashboard under "Customer privacy".
  # The Rails endpoints for them remain implemented.
  config.webhooks = [
    { topic: 'products/create', address: '/webhooks/products_create' },
    { topic: 'products/update', address: '/webhooks/products_update' },
    { topic: 'products/delete', address: '/webhooks/products_delete' },
    { topic: 'app/uninstalled', address: '/webhooks/app_uninstalled' },
    { topic: 'shop/update', address: '/webhooks/shop_update' }
  ]

  # App Proxy Configuration
  config.api_key = ENV.fetch('SHOPIFY_API_KEY') { Rails.application.credentials.dig(:shopify, :api_key) || raise('SHOPIFY_API_KEY missing') }
  config.secret = ENV.fetch('SHOPIFY_API_SECRET') { Rails.application.credentials.dig(:shopify, :api_secret) || raise('SHOPIFY_API_SECRET missing') }
end

# Initialize the low-level shopify_api context (required by OAuth + GraphQL client).
# HOST is the public base URL of this app (ngrok/Fly URL in production, localhost in dev).
Rails.application.config.after_initialize do
  ShopifyAPI::Context.setup(
    api_key: ShopifyApp.configuration.api_key,
    api_secret_key: ShopifyApp.configuration.secret,
    api_version: ShopifyApp.configuration.api_version,
    host: ENV['HOST'] || 'http://localhost:3000',
    scope: ShopifyApp.configuration.scope,
    is_private: !ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', '').empty?,
    is_embedded: ShopifyApp.configuration.embedded_app,
    log_level: :info,
    logger: Rails.logger,
    private_shop: ENV.fetch('SHOPIFY_APP_PRIVATE_SHOP', nil),
    user_agent_prefix: "ShopifyApp/#{ShopifyApp::VERSION}"
  )
end
