# Development-only harness that renders the real Theme App Extension widget
# (same CSS/JS/markup shipped to Shopify themes) against this app's own API.
# Used for demos, screenshots and the walkthrough video.
# The extension assets themselves are served by the Rack endpoint defined
# next to these routes in config/routes.rb.
class StorefrontPreviewController < ApplicationController
  layout "storefront_preview"
  include DemoCatalog

  helper_method :current_shop

  attr_reader :current_shop

  def index
    @shop_name = shop&.name.presence || "Demo Auto Parts Store"
    @products = distinct_products.first(12)
  end

  # My Garage page — vehicles saved by the shopper (localStorage), kept in
  # sync with the selector widget's garage.
  def garage; end

  # Simulated Shopify collection results page. The widget's "Find Parts" button
  # redirects here with a `year|make|model` filter token; we run it through the
  # same FitmentSearchService the storefront uses and show matching parts.
  # Also supports ?category=Brakes style browsing without a vehicle selected.
  def collection
    token = params[FILTER_PARAM].to_s
    @year, @make, @model, @trim, @engine = token.split("|")
    @make = pretty_case(@make)
    @model = pretty_case(@model)
    @category = params[:category].presence

    if @year.present? && @make.present? && @model.present?
      results = FitmentSearchService.new(shop).search_products(
        year: @year, make: @make, model: @model,
        trim: @trim.presence, engine: @engine.presence
      )
      @vehicle = results[:vehicle]
      @products = results[:products]
    else
      @vehicle = nil
      @products = distinct_products
    end
    @products = @products.select { |p| p[:category] == @category } if @category
  end

  # Product detail page — same data the Shopify PDP would carry (title, price,
  # brand, SKU, description) plus demo-only spec sheet and the compatible
  # vehicle list served by the fitment API.
  def product
    # Route params carry only the bare numeric id; the DB stores GraphQL GIDs.
    # Match either form (mirrors FitmentSearchService.product_id_variants).
    pid = params[:product_id].to_s
    candidates = [pid, "gid://shopify/Product/#{pid}"]
    @product = distinct_products.find { |p| candidates.include?(p[:product_id].to_s) }
    return render_demo_404 unless @product

    @specs = PRODUCT_SPECS[@product[:sku]] || {}
    @fitments = compatible_fitments(@product[:product_id])
  end

  def support; end

  # Public privacy policy (App Store submission requires a public URL).
  # Rendered from docs/PRIVACY.md; MarkdownRenderer supports exactly the
  # constructs that document uses (headings, tables, lists, bold, links) and
  # HTML-escapes everything first.
  def privacy
    doc_path = Rails.root.join("docs/PRIVACY.md")
    @privacy_html = MarkdownRenderer.new(File.read(doc_path)).to_html
    render layout: "storefront_preview"
  end

  private

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
    render template: "admin/dashboard/index", layout: "embedded_app"
  end

  def admin_sync
    @current_shop = shop
    @pending_count = shop.vehicle_product_fitments.pending_sync.count
    @synced_count = shop.vehicle_product_fitments.synced.count
    @total_products = shop.unique_products_count
    @sync_logs = shop.metafield_sync_logs.recent.limit(20)
    @pending_sync_count = @pending_count
    render template: "admin/sync/show", layout: "embedded_app"
  end

  def admin_fitments
    @current_shop = shop
    @fitments = shop.vehicle_product_fitments.includes(:vehicle).order(created_at: :desc).limit(20)
    @page = 1
    @per_page = 20
    @total_count = shop.vehicle_product_fitments.count
    render template: "admin/product_fitments/index", layout: "embedded_app"
  end

  def admin_vehicles
    @current_shop = shop
    @vehicles = Vehicle.active.order(year: :desc, make: :asc, model: :asc).limit(25)
    @page = 1
    @per_page = 25
    @total_count = Vehicle.active.count
    @distinct_years = Vehicle.distinct_years
    render template: "admin/vehicles/index", layout: "embedded_app"
  end

  def admin_settings
    @current_shop = shop
    @settings = shop.settings
    render template: "admin/settings/show", layout: "embedded_app"
  end

  def admin_imports
    @current_shop = shop
    @recent_fitments_count = shop.vehicle_product_fitments.count
    render template: "admin/bulk_imports/index", layout: "embedded_app"
  end

  def render_demo_404
    html = '<p style="padding:48px;text-align:center;font-family:sans-serif">' \
           'Product not found. <a href="/demo">Back to shop</a></p>'
    # rubocop:disable-next Rails/OutputSafety -- fixed demo string, no user input
    render html: html.html_safe, layout: false, status: :not_found
  end

  def shop
    @shop ||= DemoShopResolver.resolve
  end

  def compatible_fitments(product_id)
    return [] unless shop

    shop.vehicle_product_fitments.includes(:vehicle)
        .where(product_id: product_id)
        .map { |f| f.universal_fit? ? "Universal — fits all vehicles" : f.vehicle&.display_name }
        .compact.uniq
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
        universal: f.universal_fit?,
        image: DEMO_PRODUCT_IMAGES[f.sku]
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
