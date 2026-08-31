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
    # Featured Parts loads dynamically via /demo/api/products (see
    # _dynamic_catalog), so no catalog is passed to the template here.
    @shop_name = shop&.name.presence || "Demo Auto Parts Store"
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

    # Initial page is rendered server-side (page 1 of a paginated set); the
    # shared dynamic-catalog loader appends further pages from /demo/api/products
    # as the shopper scrolls. @page drives the data-next-page attribute.
    @per = 24
    @page = 1

    if @year.present? && @make.present? && @model.present?
      results = FitmentSearchService.new(shop).search_products(
        year: @year, make: @make, model: @model,
        trim: @trim.presence, engine: @engine.presence,
        limit: @per, page: @page
      )
      @vehicle = results[:vehicle]
      @total = results[:total_count]
      @products = results[:products]
    else
      @vehicle = nil
      all = distinct_products
      all = all.select { |p| p[:category] == @category } if @category
      @total = all.size
      @products = all.first(@per)
    end
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

  def about; end

  # Install-guides index: every catalog product with its install time,
  # difficulty band and fitment scope, pulled from the same spec sheets the
  # product pages render.
  def guides
    @guides = distinct_products.map do |p|
      specs = PRODUCT_SPECS[p[:sku]] || {}
      install_row = (specs[:specs] || []).find do |label, _|
        label.to_s.match?(/\AInstall( time)?\z/i)
      end
      {
        **p,
        install: install_row&.last || "Full guide on the product page",
        minutes: (install_row&.last.to_s.match(/(\d+)\D*(\d+)?/) && Regexp.last_match[1]&.to_i) || 999,
        highlights: (specs[:features] || []).first(2)
      }
    end
    @guides.sort_by! { |g| [g[:minutes], g[:title].to_s] }
  end

  # Public privacy policy (App Store submission requires a public URL).
  # Rendered from docs/PRIVACY.md; MarkdownRenderer supports exactly the
  # constructs that document uses (headings, tables, lists, bold, links) and
  # HTML-escapes everything first.
  def privacy
    doc_path = Rails.root.join("docs/PRIVACY.md")
    @privacy_html = MarkdownRenderer.new(File.read(doc_path)).to_html
    render layout: "storefront_preview"
  end

  # Dev-only renders of the REAL admin views (same templates + data the
  # authenticated admin sees), used for demos/screenshots. These are dispatched
  # by the /demo/admin* routes, so they must stay PUBLIC actions — Rails raises
  # AbstractController::ActionNotFound for private ones. The real /admin routes
  # keep their embedded-session requirement unchanged.
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

  # Read-only renders of the v1.2/v1.3 pages for the public demo (screenshots
  # and walkthroughs). They mirror the Admin controllers' instance variables
  # but never mutate anything: the billing page is rendered against the demo
  # shop's real (free) plan without touching Shopify, and analytics reads the
  # demo shop's daily aggregates.
  def admin_analytics
    @current_shop = shop
    range = { "7d" => 7.days, "90d" => 90.days }.fetch(params[:range], 30.days)
    @range = { "7d" => "7d", "90d" => "90d" }.fetch(params[:range], "30d")
    @to = Time.zone.today
    @from = (@to - range + 1.day)

    @checks = FitmentAnalytic.total(shop, "checks", from: @from, to: @to)
    @fits = FitmentAnalytic.total(shop, "fits", from: @from, to: @to)
    @no_fit = FitmentAnalytic.total(shop, "no_fit", from: @from, to: @to)
    @universal = FitmentAnalytic.total(shop, "universal", from: @from, to: @to)
    @fit_rate = @checks.positive? ? ((@fits.to_f / @checks) * 100).round(1) : 0
    @checks_series = FitmentAnalytic.series(shop, "checks", from: @from, to: @to)
    @fits_series = FitmentAnalytic.series(shop, "fits", from: @from, to: @to)
    @by_make = FitmentAnalytic.by_make(shop, metric: "checks", from: @from, to: @to, count: 12)
    @make_fits = FitmentAnalytic.by_make(shop, metric: "fits", from: @from, to: @to, count: 12)
                                .to_h { |r| [r[:make], r[:value]] }
    render template: "admin/analytics/index", layout: "embedded_app"
  end

  def admin_billing
    @current_shop = shop
    @plans = BillingPlan.all
    @current_plan = shop.billing_plan_key
    @current_plan_obj = BillingPlan.find(@current_plan)
    render template: "admin/billing/show", layout: "embedded_app"
  end

  def admin_oe_numbers
    @current_shop = shop
    @oe_numbers = shop.oe_numbers.order(created_at: :desc)
    @page = 1
    @per_page = 25
    @total_count = @oe_numbers.count
    @oe_numbers = @oe_numbers.limit(@per_page)
    render template: "admin/oe_numbers/index", layout: "embedded_app"
  end
end
