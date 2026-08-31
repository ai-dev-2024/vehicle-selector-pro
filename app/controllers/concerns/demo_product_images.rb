# Centralized product-photo map for the demo storefront. Views resolve an
# image for every product via DemoProductImages.image_for: exact SKU match
# first, then a real category photo, so products added later (bulk CSV
# imports, Shopify admin) are always pictured instead of falling back to an
# icon. All files are freely-licensed photography (see
# public/demo-products/CREDITS.md; re-fetchable via
# scripts/fetch_product_photos.rb).
module DemoProductImages
  DEMO_PRODUCT_IMAGES = {
    "APX-CAI-F150-EB" => "/demo-products/intake.jpg",
    "APX-BRK-HD-TRK" => "/demo-products/brakes.jpg",
    "APX-SUSP-TACO-3IN" => "/demo-products/suspension.jpg",
    "APX-EXH-MUST-V8" => "/demo-products/exhaust.jpg",
    "APX-BMP-JL-001" => "/demo-products/bumper.jpg",
    "APX-LGT-UNIV-POD" => "/demo-products/led-pods.jpg",
    "APX-STRUT-G20-CF" => "/demo-products/strut-brace.jpg",
    "APX-OIL-KIT-0W20" => "/demo-products/oil-kit.jpg",
    "APX-WIP-BLD-24" => "/demo-products/wiper-blades.jpg",
    "APX-BAT-AGM-H7" => "/demo-products/battery.jpg",
    "APX-CAB-AIR-TAC" => "/demo-products/cabin-filter.jpg",
    "APX-BRK-PAD-FRT" => "/demo-products/brake-pads.jpg",
    "APX-SUSP-SHCK-JL" => "/demo-products/shocks.jpg",
    "APX-EXH-TIP-MST" => "/demo-products/exhaust-tips.jpg",
    "APX-AIR-FIL-F150" => "/demo-products/air-filter.jpg",
    "APX-LIN-UNIV-FLR" => "/demo-products/floor-liners.jpg",
    "APX-TOW-HITCH-F150" => "/demo-products/trailer-hitch.jpg",
    "APX-BRK-PAD-RR-4RN" => "/demo-products/brake-pads.jpg",
    "APX-CAI-MST-EB" => "/demo-products/intake-mustang.jpg",
    "APX-LGT-BAR-20-UNIV" => "/demo-products/light-bar.jpg",
    "APX-SUSP-LFT-4RN-2IN" => "/demo-products/leveling-kit.jpg",
    "APX-BED-MAT-TAC" => "/demo-products/bed-mat.jpg",
    "APX-CAI-RAM-V8" => "/demo-products/intake-ram.jpg",
    "APX-EXH-RAM-V8" => "/demo-products/exhaust-ram.jpg",
    "APX-SUSP-LFT-RAM-25" => "/demo-products/leveling-kit.jpg",
    "APX-CAI-CIV-15T" => "/demo-products/intake-civic.jpg",
    "APX-CHP-SPR-CIV" => "/demo-products/springs-civic.jpg",
    "APX-EXT-RACK-OUT" => "/demo-products/roof-racks.jpg",
    "APX-BRK-PAD-OUT" => "/demo-products/brake-pads.jpg",
    "APX-CAI-BRN-27" => "/demo-products/intake-bronco.jpg",
    "APX-LGT-POD-BRN" => "/demo-products/pod-kit-bronco.jpg",
    "APX-TOW-HITCH-SLV" => "/demo-products/trailer-hitch.jpg",
    "APX-BRK-ROT-MST" => "/demo-products/rotors-mustang.jpg",
    "APX-SUSP-SHCK-TAC" => "/demo-products/shocks.jpg"
  }.freeze

  # Real category photos as the fallback for SKUs without a dedicated image
  # (e.g. products brought in through bulk CSV import or the Shopify admin).
  DEMO_CATEGORY_IMAGES = {
    "Air Intake" => "/demo-products/intake.jpg",
    "Brakes" => "/demo-products/brake-pads.jpg",
    "Suspension" => "/demo-products/suspension.jpg",
    "Exhaust" => "/demo-products/exhaust.jpg",
    "Bumpers & Armor" => "/demo-products/bumper.jpg",
    "Lighting" => "/demo-products/led-pods.jpg",
    "Chassis & Handling" => "/demo-products/strut-brace.jpg",
    "Maintenance" => "/demo-products/oil-kit.jpg",
    "Wipers & Visibility" => "/demo-products/wiper-blades.jpg",
    "Electrical" => "/demo-products/battery.jpg",
    "Filters" => "/demo-products/air-filter.jpg",
    "Interior & Comfort" => "/demo-products/floor-liners.jpg",
    "Towing" => "/demo-products/trailer-hitch.jpg",
    "Exterior & Racks" => "/demo-products/roof-racks.jpg"
  }.freeze

  # Exact SKU photo when available, otherwise a real photo for the category.
  def self.image_for(sku, category)
    DEMO_PRODUCT_IMAGES[sku] || DEMO_CATEGORY_IMAGES[category]
  end
end
