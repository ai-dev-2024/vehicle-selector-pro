# Public, read-only JSON API backing the /demo storefront pages.
#
# On a real Shopify storefront the widget talks to /apps/vehicle-selector/*
# where Shopify's App Proxy adds an HMAC signature proving the request came
# from the merchant's shop. The public demo site is served directly by this
# Rails app (no proxy in between), so these endpoints expose the same
# cascading-filter and fitment data against the seeded demo catalog only.
#
# Security notes:
# - Read-only: there are no write actions here.
# - Demo-scope only: data is always resolved against the demo shop (see
#   demo_shop), never against arbitrary shop domains supplied by callers.
# - Responses carry the same short-lived public cache headers as the proxy.
class DemoApiController < ActionController::Base
  skip_before_action :verify_authenticity_token
  before_action :set_demo_shop
  before_action :set_cache_headers

  # GET /demo/api/years
  def years
    available_years = search.years
    render json: { success: true, years: available_years, count: available_years.size }
  end

  # GET /demo/api/makes?year=2024
  def makes
    return missing_params!(%w[year]) if params[:year].blank?

    available_makes = search.makes(year: params[:year])
    render json: { success: true, year: params[:year].to_i, makes: available_makes, count: available_makes.size }
  end

  # GET /demo/api/models?year=2024&make=Ford
  def models
    return missing_params!(%w[year make]) if params[:year].blank? || params[:make].blank?

    available_models = search.models(year: params[:year], make: params[:make])
    render json: { success: true, year: params[:year].to_i, make: params[:make], models: available_models, count: available_models.size }
  end

  # GET /demo/api/trims?year=2024&make=Ford&model=F-150
  def trims
    return missing_params!(%w[year make model]) if params[:year].blank? || params[:make].blank? || params[:model].blank?

    available_trims = search.trims(year: params[:year], make: params[:make], model: params[:model])
    render json: {
      success: true, year: params[:year].to_i, make: params[:make], model: params[:model],
      trims: available_trims, count: available_trims.size
    }
  end

  # GET /demo/api/engines?year=2024&make=Ford&model=F-150&trim=Lariat
  def engines
    return missing_params!(%w[year make model]) if params[:year].blank? || params[:make].blank? || params[:model].blank?

    available_engines = search.engines(year: params[:year], make: params[:make], model: params[:model], trim: params[:trim])
    render json: {
      success: true, year: params[:year].to_i, make: params[:make], model: params[:model],
      trim: params[:trim], engines: available_engines, count: available_engines.size
    }
  end

  # GET /demo/api/search?year=2024&make=Ford&model=F-150
  def search_products
    return missing_params!(%w[year make model]) if params[:year].blank? || params[:make].blank? || params[:model].blank?

    results = search.search_products(
      year: params[:year], make: params[:make], model: params[:model],
      trim: params[:trim], engine: params[:engine],
      limit: params[:limit] || 50, page: params[:page] || 1
    )
    render json: { success: true, data: results }
  end

  # GET /demo/api/check_fitment?product_id=gid://...&year=2024&make=Ford&model=F-150
  def check_fitment
    return missing_params!(%w[product_id]) if params[:product_id].blank?

    result = search.check_fitment(
      product_id: params[:product_id],
      year: params[:year], make: params[:make], model: params[:model],
      trim: params[:trim], engine: params[:engine]
    )
    render json: { success: true, data: result }
  end

  # GET /demo/api/product_fitments?product_id=gid://...
  def product_fitments
    return missing_params!(%w[product_id]) if params[:product_id].blank?

    fitments = @demo_shop.vehicle_product_fitments
                         .includes(:vehicle)
                         .where(product_id: params[:product_id])
                         .limit(200)
    render json: { success: true, product_id: params[:product_id], fitments: fitments.map(&:to_fitment_hash), count: fitments.size }
  end

  private

  def search
    @search ||= FitmentSearchService.new(@demo_shop)
  end

  def set_demo_shop
    demo_domain = ENV.fetch('SHOPIFY_STORE_DOMAIN', 'vehicle-selector-pro.myshopify.com')
    @demo_shop = Shop.find_by(shopify_domain: demo_domain) ||
                 Shop.active.left_joins(:vehicle_product_fitments)
                     .group(:id).order(Arel.sql('COUNT(vehicle_product_fitments.id) DESC')).first ||
                 Shop.active.first || Shop.first
    return if @demo_shop

    render json: { success: false, error: 'Demo catalog unavailable' }, status: :service_unavailable
  end

  def set_cache_headers
    response.headers['Cache-Control'] = 'public, max-age=180, stale-while-revalidate=360'
  end

  def missing_params!(required)
    render json: { success: false, error: "Missing required parameter(s): #{required.join(', ')}" }, status: :bad_request
  end
end
