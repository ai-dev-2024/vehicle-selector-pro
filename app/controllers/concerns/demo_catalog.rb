# Demo catalog data and lookup helpers for the storefront preview harness.
# Extracted from StorefrontPreviewController so the controller stays
# focused on routing/actions; all content here is demo-only.
module DemoCatalog
  extend ActiveSupport::Concern

  # Shopify collection-filter metafield key. The widget's "Find Parts" action
  # redirects to the demo collection page with this param carrying the
  # "year|make|model|trim|engine" token.
  FILTER_PARAM = "filter.v.m.custom.vehicle_fitment".freeze

  # Centralized SKU -> image map for the demo catalog. Views read p[:image]
  # from distinct_products, so adding a product only means adding a seed row
  # plus an entry here (photo first, category SVG fallback below).
  DEMO_PRODUCT_IMAGES = {
    "APX-CAI-F150-EB" => "/demo-products/intake.jpg",
    "APX-BRK-HD-TRK" => "/demo-products/brakes.jpg",
    "APX-SUSP-TACO-3IN" => "/demo-products/suspension.jpg",
    "APX-EXH-MUST-V8" => "/demo-products/exhaust.jpg",
    "APX-BMP-JL-001" => "/demo-products/bumper.jpg",
    "APX-LGT-UNIV-POD" => "/demo-products/led-pods.jpg",
    "APX-STRUT-G20-CF" => "/demo-products/strut-brace.jpg",
    "APX-OIL-KIT-0W20" => "/demo-products/oil-kit.svg",
    "APX-WIP-BLD-24" => "/demo-products/wiper-blades.svg",
    "APX-BAT-AGM-H7" => "/demo-products/battery.svg",
    "APX-CAB-AIR-TAC" => "/demo-products/cabin-filter.svg",
    "APX-BRK-PAD-FRT" => "/demo-products/brake-pads.svg",
    "APX-SUSP-SHCK-JL" => "/demo-products/shocks.svg",
    "APX-EXH-TIP-MST" => "/demo-products/exhaust-tips.svg",
    "APX-AIR-FIL-F150" => "/demo-products/air-filter.svg",
    "APX-LIN-UNIV-FLR" => "/demo-products/floor-liners.svg",
    "APX-TOW-HITCH-F150" => "/demo-products/trailer-hitch.svg",
    "APX-BRK-PAD-RR-4RN" => "/demo-products/brake-pads-rear.svg",
    "APX-CAI-MST-EB" => "/demo-products/intake-mustang.svg",
    "APX-LGT-BAR-20-UNIV" => "/demo-products/light-bar.svg",
    "APX-SUSP-LFT-4RN-2IN" => "/demo-products/leveling-kit.svg",
    "APX-BED-MAT-TAC" => "/demo-products/bed-mat.svg",
    "APX-CAI-RAM-V8" => "/demo-products/intake-ram.svg",
    "APX-EXH-RAM-V8" => "/demo-products/exhaust-ram.svg",
    "APX-SUSP-LFT-RAM-25" => "/demo-products/leveling-ram.svg",
    "APX-CAI-CIV-15T" => "/demo-products/intake-civic.svg",
    "APX-CHP-SPR-CIV" => "/demo-products/springs-civic.svg",
    "APX-EXT-RACK-OUT" => "/demo-products/roof-racks.svg",
    "APX-BRK-PAD-OUT" => "/demo-products/pads-outback.svg",
    "APX-CAI-BRN-27" => "/demo-products/intake-bronco.svg",
    "APX-LGT-POD-BRN" => "/demo-products/pod-kit-bronco.svg",
    "APX-TOW-HITCH-SLV" => "/demo-products/hitch-silverado.svg",
    "APX-BRK-ROT-MST" => "/demo-products/rotors-mustang.svg",
    "APX-SUSP-SHCK-TAC" => "/demo-products/shocks-tacoma.svg"
  }.freeze

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
