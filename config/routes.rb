Rails.application.routes.draw do
  root to: 'admin/dashboard#index'

  # Shopify Embedded Admin Routes
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'

    resources :product_fitments do
      collection do
        post :bulk_assign
        post :bulk_delete
        get :search_products
      end
    end

    resources :vehicles do
      collection do
        get :ymm_tree
        get :years
        get :makes
        get :models
        get :trims
        get :engines
      end
    end

    resources :bulk_imports, only: [:index, :create, :show] do
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

  # Direct API for fallback or headless storefronts
  namespace :api do
    namespace :v1 do
      namespace :storefront do
        get 'years', to: '/app_proxy/vehicle_filters#years'
        get 'makes', to: '/app_proxy/vehicle_filters#makes'
        get 'models', to: '/app_proxy/vehicle_filters#models'
        get 'trims', to: '/app_proxy/vehicle_filters#trims'
        get 'engines', to: '/app_proxy/vehicle_filters#engines'
        get 'search', to: '/app_proxy/vehicle_filters#search'
        get 'check_fitment', to: '/app_proxy/fitments#check'
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
  end

  # Healthcheck for load balancers and container orchestrators
  get 'up', to: proc { [200, { 'Content-Type' => 'application/json' }, ['{"status":"ok"}']] }
end
