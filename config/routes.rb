Rails.application.routes.draw do
  # NOTE: ShopifyApp::Engine is mounted at the BOTTOM of this file so the
  # app's own /webhooks/* controllers win over the engine's catch-all
  # /webhooks/(:type) route (which would raise NoWebhookHandler). Unmatched
  # paths such as /login and /auth/shopify/callback cascade to the engine.
  root to: 'admin/dashboard#index'

  # Shopify Embedded Admin Routes
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'

    resources :product_fitments, only: [:index, :new, :create, :edit, :update, :destroy] do
      collection do
        post :bulk_assign
        post :bulk_delete
        get :search_products
      end
    end

    resources :vehicles, only: [:index, :show] do
      collection do
        get :ymm_tree
        get :years
        get :makes
        get :models
        get :trims
        get :engines
      end
    end

    resources :bulk_imports, only: [:index, :create] do
      collection do
        get :sample_template
      end
    end

    resource :sync, controller: 'sync', only: [:show] do
      post :trigger_all
      post :trigger_product
      get :status
    end

    resource :settings, only: [:show, :update]
  end

  # Shopify App Proxy Endpoints (Mounted at storefront path /apps/vehicle-selector)
  namespace :app_proxy, path: 'apps/vehicle-selector' do
    get 'years', to: 'vehicle_filters#years'
    get 'makes', to: 'vehicle_filters#makes'
    get 'models', to: 'vehicle_filters#models'
    get 'trims', to: 'vehicle_filters#trims'
    get 'engines', to: 'vehicle_filters#engines'
    get 'search', to: 'vehicle_filters#search'
    get 'check_fitment', to: 'fitments#check'
    get 'product_fitments', to: 'fitments#product_fitments'
    get 'garage', to: 'garage#index'
  end

  # Headless fallback API - requires HMAC signature same as App Proxy (do not expose unauthenticated)
  # Kept for internal use only; secured via AppProxySignatureVerifier
  namespace :api do
    namespace :v1 do
      namespace :storefront do
        get 'years', to: 'app_proxy/vehicle_filters#years'
        get 'makes', to: 'app_proxy/vehicle_filters#makes'
        get 'models', to: 'app_proxy/vehicle_filters#models'
        get 'trims', to: 'app_proxy/vehicle_filters#trims'
        get 'engines', to: 'app_proxy/vehicle_filters#engines'
        get 'search', to: 'app_proxy/vehicle_filters#search'
        get 'check_fitment', to: 'app_proxy/fitments#check'
      end
    end
  end

  # Webhook Ingestion Endpoints
  namespace :webhooks do
    post 'products_create', to: 'products#create'
    post 'products_update', to: 'products#update'
    post 'products_delete', to: 'products#destroy'
    post 'app_uninstalled', to: 'app_uninstalled#create'
    post 'shop_update', to: 'shop_updates#create'
    post 'customers_data_request', to: 'customers#data_request'
    post 'customers_redact', to: 'customers#redact'
    post 'shop_redact', to: 'shop#redact'
  end

  # Healthcheck for load balancers and container orchestrators
  get 'up', to: proc { [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }

  # Storefront preview harness (development only): renders the real Theme App
  # Extension widget assets against this app's own API so the storefront
  # experience can be demonstrated and recorded outside a Shopify theme.
  if Rails.env.development?
    get 'storefront_preview', to: 'storefront_preview#index'
    get 'collections/storefront_preview', to: 'storefront_preview#collection'
    get 'admin_preview', to: 'storefront_preview#admin_dashboard'
    get 'admin_preview/sync', to: 'storefront_preview#admin_sync'
    ext_assets = Rails.root.join('extensions', 'vehicle-selector-pro-extension', 'assets')
    get 'ext-assets/:filename', format: false, constraints: { filename: /[^\/]+/ },
        to: lambda { |env|
          filename = File.basename(env['action_dispatch.request.path_parameters'][:filename].to_s)
          path = ext_assets.join(filename)
          if File.file?(path)
            type = filename.end_with?('.css') ? 'text/css' : 'application/javascript'
            [200, { 'content-type' => type }, [File.read(path)]]
          else
            [404, { 'content-type' => 'text/plain' }, ['not found']]
          end
        }
  end

  # Mounted last so application routes take precedence; the engine handles
  # /login, /auth/shopify/callback and anything else it defines.
  mount ShopifyApp::Engine, at: '/'
end
