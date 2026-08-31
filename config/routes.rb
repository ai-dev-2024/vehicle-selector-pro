Rails.application.routes.draw do
  # NOTE: ShopifyApp::Engine is mounted at the BOTTOM of this file so the
  # app's own /webhooks/* controllers win over the engine's catch-all
  # /webhooks/(:type) route (which would raise NoWebhookHandler). Unmatched
  # paths such as /login and /auth/shopify/callback cascade to the engine.
  root to: "admin/dashboard#index"

  # Shopify Embedded Admin Routes
  namespace :admin do
    get "dashboard", to: "dashboard#index"

    resources :product_fitments, only: %i[index new create edit update destroy] do
      collection do
        post :bulk_assign
        post :bulk_delete
        get :search_products
      end
    end

    resources :vehicles, only: %i[index show] do
      collection do
        get :ymm_tree
        get :years
        get :makes
        get :models
        get :trims
        get :engines
      end
    end

    resources :bulk_imports, only: %i[index create] do
      collection do
        get :sample_template
      end
    end

    resource :sync, controller: "sync", only: [:show] do
      post :trigger_all
      post :trigger_product
      post :backfill
      get :status
    end

    resource :settings, only: %i[show update]
  end

  # Shopify App Proxy Endpoints (Mounted at storefront path /apps/vehicle-selector)
  namespace :app_proxy, path: "apps/vehicle-selector" do
    get "years", to: "vehicle_filters#years"
    get "makes", to: "vehicle_filters#makes"
    get "models", to: "vehicle_filters#models"
    get "trims", to: "vehicle_filters#trims"
    get "engines", to: "vehicle_filters#engines"
    get "search", to: "vehicle_filters#search"
    get "check_fitment", to: "fitments#check"
    get "product_fitments", to: "fitments#product_fitments"
    get "garage", to: "garage#index"
  end

  # Headless fallback API - requires HMAC signature same as App Proxy (do not expose unauthenticated)
  # Kept for internal use only; secured via AppProxySignatureVerifier
  namespace :api do
    namespace :v1 do
      namespace :storefront do
        get "years", to: "app_proxy/vehicle_filters#years"
        get "makes", to: "app_proxy/vehicle_filters#makes"
        get "models", to: "app_proxy/vehicle_filters#models"
        get "trims", to: "app_proxy/vehicle_filters#trims"
        get "engines", to: "app_proxy/vehicle_filters#engines"
        get "search", to: "app_proxy/vehicle_filters#search"
        get "check_fitment", to: "app_proxy/fitments#check"
      end
    end
  end

  # Webhook Ingestion Endpoints
  namespace :webhooks do
    post "products_create", to: "products#create"
    post "products_update", to: "products#update"
    post "products_delete", to: "products#destroy"
    post "app_uninstalled", to: "app_uninstalled#create"
    post "shop_update", to: "shop_updates#create"
    post "customers_data_request", to: "customers#data_request"
    post "customers_redact", to: "customers#redact"
    post "shop_redact", to: "shop#redact"
  end

  # Healthcheck for load balancers and container orchestrators
  get "up", to: proc { [200, { "Content-Type" => "application/json" }, ['{"status":"ok"}']] }

  # Public live-demo routes (all environments): read-only renders of the
  # storefront selector and admin dashboard against the bundled demo catalog.
  # No authentication required and no write operations are exposed, so anyone
  # can try the full Year/Make/Model/Trim experience without a Shopify session.
  get "demo", to: "storefront_preview#index"
  get "demo/collection", to: "storefront_preview#collection"
  get "demo/products/:product_id", to: "storefront_preview#product", as: :demo_product
  get "demo/support", to: "storefront_preview#support"
  get "demo/about", to: "storefront_preview#about"
  get "demo/guides", to: "storefront_preview#guides"
  get "privacy", to: "storefront_preview#privacy"
  get "demo/garage", to: "storefront_preview#garage"
  get "demo/admin", to: "storefront_preview#admin_dashboard"
  get "demo/admin/sync", to: "storefront_preview#admin_sync"
  get "demo/admin/fitments", to: "storefront_preview#admin_fitments"
  get "demo/admin/vehicles", to: "storefront_preview#admin_vehicles"
  get "demo/admin/settings", to: "storefront_preview#admin_settings"
  get "demo/admin/imports", to: "storefront_preview#admin_imports"

  # Public read-only JSON API for the demo storefront widget. The real
  # storefront uses the HMAC-signed App Proxy; the demo is served directly by
  # Rails so it needs its own unauthenticated-but-demo-scoped endpoints.
  namespace :demo, path: "demo/api" do
    get "years", to: "/demo_api#years"
    get "makes", to: "/demo_api#makes"
    get "models", to: "/demo_api#models"
    get "trims", to: "/demo_api#trims"
    get "engines", to: "/demo_api#engines"
    get "search", to: "/demo_api#search_products"
    get "products", to: "/demo_api#products"
    get "check_fitment", to: "/demo_api#check_fitment"
    get "product_fitments", to: "/demo_api#product_fitments"
  end

  # Theme App Extension widget assets used by the demo pages. Filenames are
  # sanitized with File.basename and served read-only from the bundled
  # extension assets directory, so this is safe to expose in production.
  # Responses are cacheable: the layout references the assets with a ?v=
  # query string, so bump that version in storefront_preview.html.erb whenever
  # vehicle-selector.js/css change and browsers always pick up the new bytes.
  ext_assets = Rails.root.join("extensions/vehicle-selector-pro-extension/assets")
  get "ext-assets/:filename", format: false, constraints: { filename: %r{[^/]+} },
                              to: lambda { |env|
                                filename = File.basename(env["action_dispatch.request.path_parameters"][:filename].to_s)
                                path = ext_assets.join(filename)
                                if File.file?(path)
                                  type = filename.end_with?(".css") ? "text/css" : "application/javascript"
                                  headers = { "content-type" => type,
                                              "cache-control" => "public, max-age=31536000, immutable" }
                                  [200, headers, [File.read(path)]]
                                else
                                  [404, { "content-type" => "text/plain" }, ["not found"]]
                                end
                              }

  # Legacy development preview paths, kept so local bookmarks keep working.
  if Rails.env.development?
    get "storefront_preview", to: "storefront_preview#index"
    get "collections/storefront_preview", to: "storefront_preview#collection"
    get "storefront_preview/products/:product_id", to: "storefront_preview#product"
    get "storefront_preview/support", to: "storefront_preview#support"
    get "admin_preview", to: "storefront_preview#admin_dashboard"
    get "admin_preview/sync", to: "storefront_preview#admin_sync"
  end

  # Mounted last so application routes take precedence; the engine handles
  # /login, /auth/shopify/callback and anything else it defines.
  mount ShopifyApp::Engine, at: "/"
end
