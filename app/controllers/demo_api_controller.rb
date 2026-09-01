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
class DemoApiController < ApplicationController
  include DemoCatalog

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
    render json: { success: true, year: params[:year].to_i, make: params[:make], models: available_models,
                   count: available_models.size }
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

    available_engines = search.engines(year: params[:year], make: params[:make], model: params[:model],
                                       trim: params[:trim])
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

  # GET /demo/api/products?page=1&limit=24[&category=X][&token=year|make|model|trim|engine][&featured=1]
  #
  # Backs the dynamically-loaded featured grid and the infinite-scroll
  # collection: returns one page of product cards with enough metadata to know
  # when to stop (has_more) so the client can keep fetching until the catalog
  # is fully loaded. Mirrors how a real Shopify storefront paginates a
  # collection (limit/page + a filtered product set). With featured=1 the set
  # is narrowed to the curated FEATURED_SKUS bestsellers, so the shop page's
  # grid is a fixed hand-picked storefront while the collection page streams
  # the whole catalog.
  # rubocop:disable-next Metrics/AbcSize -- single flat action branching between vehicle-token and
  # distinct-catalog pagination; splitting it would hide the two paths from the reader
  def products
    per = params[:limit].to_i.clamp(1, 100)
    page = [params[:page].to_i, 1].max
    offset = (page - 1) * per
    category = params[:category].presence
    featured = params[:featured].present?

    year, make, model, trim, engine = params[:token].to_s.split("|")
    if year.present? && make.present? && model.present?
      results = search.search_products(
        year: year, make: make, model: model,
        trim: trim.presence, engine: engine.presence,
        limit: per, page: page
      )
      products = results[:products].map { |p| card_payload(p) }
      total = results[:total_count]
    else
      all = distinct_products
      all = all.select { |p| p[:category] == category } if category
      if featured
        all = all.select { |p| FEATURED_SKUS.include?(p[:sku]) }
                 .sort_by { |p| FEATURED_SKUS.index(p[:sku]) }
      end
      total = all.size
      products = all.drop(offset).first(per).map { |p| card_payload(p) }
    end

    render json: {
      success: true,
      products: products,
      total: total,
      page: page,
      limit: per,
      has_more: (offset + products.size) < total
    }
  end

  # GET /demo/api/product_fitments?product_id=gid://...
  def product_fitments
    return missing_params!(%w[product_id]) if params[:product_id].blank?

    fitments = @demo_shop.vehicle_product_fitments
                         .includes(:vehicle)
                         .where(product_id: params[:product_id])
                         .limit(200)
    render json: { success: true, product_id: params[:product_id], fitments: fitments.map(&:to_fitment_hash),
                   count: fitments.size }
  end

  private

  # Normalize either payload shape (distinct_products uses :title, the search
  # service uses :product_title) into the single card shape the client renders.
  def card_payload(product)
    {
      product_id: product[:product_id],
      title: product[:title] || product[:product_title],
      sku: product[:sku],
      brand: product[:brand],
      category: product[:category],
      short_description: product[:short_description],
      price_cents: product[:price_cents],
      universal: product[:universal],
      image: product[:image],
      fitment_notes: product[:fitment_notes]
    }
  end

  def search
    @search ||= FitmentSearchService.new(@demo_shop)
  end

  def set_demo_shop
    @demo_shop = DemoShopResolver.resolve
    return if @demo_shop

    render json: { success: false, error: "Demo catalog unavailable" }, status: :service_unavailable
  end

  def set_cache_headers
    response.headers["Cache-Control"] = "public, max-age=180, stale-while-revalidate=360"
  end

  def missing_params!(required)
    render json: { success: false, error: "Missing required parameter(s): #{required.join(', ')}" },
           status: :bad_request
  end
end
