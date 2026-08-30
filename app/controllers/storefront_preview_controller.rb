# Development-only harness that renders the real Theme App Extension widget
# (same CSS/JS/markup shipped to Shopify themes) against this app's own API.
# Used for demos, screenshots and the walkthrough video.
# The extension assets themselves are served by the Rack endpoint defined
# next to these routes in config/routes.rb.
class StorefrontPreviewController < ActionController::Base
  layout 'storefront_preview'

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

  private

  def shop
    @shop ||= Shop.active.first || Shop.first
  end

  def distinct_products
    seen = {}
    (shop&.vehicle_product_fitments || []).each do |f|
      next if f.product_id.blank?
      seen[f.product_id] ||= {
        product_id: f.product_id,
        title: f.product_title.presence || f.product_id,
        sku: f.sku,
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
