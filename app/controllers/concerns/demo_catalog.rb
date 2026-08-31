# Demo catalog data and lookup helpers for the storefront preview harness.
# Extracted from StorefrontPreviewController so the controller stays
# focused on routing/actions; all content here is demo-only.
module DemoCatalog
  extend ActiveSupport::Concern

  # Shopify collection-filter metafield key. The widget's "Find Parts" action
  # redirects to the demo collection page with this param carrying the
  # "year|make|model|trim|engine" token.
  FILTER_PARAM = "filter.v.m.custom.vehicle_fitment".freeze

  # Shared with FitmentSearchService so every render path (home, collection,
  # search results) resolves the same product photos. See demo_product_images.rb.
  DEMO_PRODUCT_IMAGES = DemoProductImages::DEMO_PRODUCT_IMAGES

  # Spec sheets live in DemoProductSpecs (pure static data module).
  PRODUCT_SPECS = DemoProductSpecs::PRODUCT_SPECS

  private

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
        image: DemoProductImages.image_for(f.sku, f.category)
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
