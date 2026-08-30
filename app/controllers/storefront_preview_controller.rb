# Development-only harness that renders the real Theme App Extension widget
# (same CSS/JS/markup shipped to Shopify themes) against this app's own API.
# Used for demos, screenshots and the walkthrough video.
# The extension assets themselves are served by the Rack endpoint defined
# next to these routes in config/routes.rb.
class StorefrontPreviewController < ActionController::Base
  layout 'storefront_preview'
  helper_method :current_shop

  def current_shop
    @current_shop
  end

  FILTER_PARAM = 'filter.v.m.custom.vehicle_fitment'.freeze

  def index
    @shop_name = shop&.name.presence || 'Demo Auto Parts Store'
    @products = distinct_products.first(8)
  end

  # Simulated Shopify collection results page. The widget's "Find Parts" button
  # redirects here with a `year|make|model` filter token; we run it through the
  # same FitmentSearchService the storefront uses and show matching parts.
  def collection
    token = params[FILTER_PARAM].to_s
    @year, @make, @model, @trim, @engine = token.split('|')
    @make = pretty_case(@make)
    @model = pretty_case(@model)

    if @year.present? && @make.present? && @model.present?
      results = FitmentSearchService.new(shop).search_products(
        year: @year, make: @make, model: @model,
        trim: @trim.presence, engine: @engine.presence
      )
      @vehicle = results[:vehicle]
      @products = results[:products]
    else
      @vehicle = nil
      @products = []
    end
  end

  # Dev-only renders of the REAL admin views (same templates + data the
  # authenticated admin sees), used for demos/screenshots. The real /admin
  # routes keep their embedded-session requirement unchanged.
  def admin_dashboard
    @current_shop = shop
    @total_fitments = shop.vehicle_product_fitments.count
    @unique_products = shop.unique_products_count
    @total_vehicles = shop.vehicles.count
    @universal_products = shop.vehicle_product_fitments.universal.count
    @pending_sync_count = shop.vehicle_product_fitments.pending_sync.count
    @synced_count = shop.vehicle_product_fitments.synced.count
    @coverage_pct = ((@synced_count.to_f / [shop.vehicle_product_fitments.count, 1].max) * 100).round(1)
    @recent_fitments = shop.vehicle_product_fitments.includes(:vehicle).order(created_at: :desc).limit(10)
    @recent_sync_logs = shop.metafield_sync_logs.recent.limit(5)
    render template: 'admin/dashboard/index', layout: 'embedded_app'
  end

  def admin_sync
    @current_shop = shop
    @pending_count = shop.vehicle_product_fitments.pending_sync.count
    @synced_count = shop.vehicle_product_fitments.synced.count
    @total_products = shop.unique_products_count
    @sync_logs = shop.metafield_sync_logs.recent.limit(20)
    @pending_sync_count = @pending_count
    render template: 'admin/sync/show', layout: 'embedded_app'
  end

  private

  # The demo must always render the shop that actually holds the seeded demo
  # catalog. A real store can hold both an OAuth-installed shop row and the
  # seeded demo row; prefer the demo domain, then the shop with the most
  # fitments, so the public /demo pages never render an empty catalog.
  def shop
    @shop ||= begin
      demo_domain = ENV.fetch('SHOPIFY_STORE_DOMAIN', 'vehicle-selector-pro.myshopify.com')
      Shop.find_by(shopify_domain: demo_domain) ||
        Shop.active.left_joins(:vehicle_product_fitments)
            .group(:id).order(Arel.sql('COUNT(vehicle_product_fitments.id) DESC')).first ||
        Shop.active.first || Shop.first
    end
  end

  def distinct_products
    seen = {}
    (shop&.vehicle_product_fitments || []).each do |f|
      next if f.product_id.blank?
      seen[f.product_id] ||= {
        product_id: f.product_id,
        title: f.product_title.presence || f.product_id,
        sku: f.sku,
        brand: f.brand,
        category: f.category,
        price_cents: f.price_cents,
        short_description: f.short_description,
        universal: f.universal_fit?
      }
    end
    seen.values
  end

  # Capitalize alphabetic words while keeping separators intact, so that a
  # lowercased filter token like "f-150" renders as "F-150" (titleize would
  # incorrectly produce "F 150").
  def pretty_case(value)
    value.to_s.split(/(\W+)/).map { |part| part =~ /\A[a-z]/ ? part.capitalize : part }.join.presence
  end
end
