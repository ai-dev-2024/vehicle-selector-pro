# Development-only harness that renders the real Theme App Extension widget
# (same CSS/JS/markup shipped to Shopify themes) against this app's own API.
# Used for demos, screenshots and the walkthrough video.
# The extension assets themselves are served by the Rack endpoint defined
# next to these routes in config/routes.rb.
class StorefrontPreviewController < ApplicationController
  layout "storefront_preview"
  helper_method :current_shop

  attr_reader :current_shop

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
    "APX-BED-MAT-TAC" => "/demo-products/bed-mat.svg"
  }.freeze

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

  # Demo-only spec sheets for the seeded catalog. Details mirror typical
  # real-world manufacturer spec sheets for each part type (materials,
  # dimensions, power figures, included hardware, warranty).
  PRODUCT_SPECS = {
    "APX-CAI-F150-EB" => {
      features: [
        "High-flow roto-molded intake tube with smooth interior walls for maximum airflow",
        "Washable oiled cotton-gauze air filter (up to 100k miles between cleaning)",
        "Heat shield seals against the engine bay to pull cool outside air",
        "Dyno-verified gains of +18 hp / +24 lb-ft on the 3.5L EcoBoost"
      ],
      specs: [
        ["Material", "Roto-molded cross-linked polyethylene"],
        ["Filter type", 'Oiled cotton gauze, conical 6" inlet'],
        ["Estimated gains", "+18 hp / +24 lb-ft @ the wheels"],
        ["Install time", "60–90 minutes, hand tools only"],
        ["Warranty", "Lifetime limited (filter: 1 year)"]
      ]
    },
    "APX-BRK-HD-TRK" => {
      features: [
        "Drilled & slotted rotors dissipate heat and evacuate water and brake dust",
        "Carbon-ceramic pad compound rated for severe-duty and towing service",
        "G3000-grade cast iron, precision-machined and mill-balanced",
        "Includes stainless-steel pad shims and new caliper hardware"
      ],
      specs: [
        ["Rotor material", "G3000 cast iron, Geomet-coated"],
        ["Rotor finish", "Drilled & slotted, non-directional"],
        ["Pad compound", "Carbon-ceramic, severe-duty rated"],
        ["Included hardware", "Shims, clips, anti-rattle kit"],
        ["Warranty", "2 years / 24,000 miles"]
      ]
    },
    "APX-SUSP-TACO-3IN" => {
      features: [
        'True 3" lift over stock with properly indexed coil springs',
        "Billet 6061 upper control arms restore alignment at lifted ride height",
        "Pre-tuned coilovers ride like stock — no bouncy overload springs",
        'Clears 33" tires on factory wheels; extended brake lines included'
      ],
      specs: [
        ["Lift height", '3 inches (adjustable 2–3.5")'],
        ["Coilovers", "Twin-tube, pre-set 600 lb/in springs"],
        ["Control arms", "Billet 6061-T6 with durometer bushings"],
        ["Tire clearance", "Up to 33 x 12.50 on stock wheels"],
        ["Warranty", "Limited lifetime on structural components"]
      ]
    },
    "APX-EXH-MUST-V8" => {
      features: [
        "Full 3-inch mandrel-bent T-304 stainless tubing — no crush bends",
        "Electronic active valves: quiet at cruise, wide-open under throttle",
        "Straight-through turbo-mufflers with burned titanium tips",
        "Bolts to factory flanges; no cutting or welding required"
      ],
      specs: [
        ["Material", "T-304 stainless steel, TIG-welded"],
        ["Tube diameter", "3.0 in mandrel-bent"],
        ["Valves", "Dual electronic, remote + rpm trigger"],
        ["Tips", "Dual 4.5 in burned-titanium, quad outlet"],
        ["Warranty", "Lifetime on materials and workmanship"]
      ]
    },
    "APX-BMP-JL-001" => {
      features: [
        "High-clearance profile gains approach angle for rock crawling",
        "11-gauge steel plate construction with reinforced mounting ribs",
        'Two welded 3/8" recovery eyes plus winch plate rated to 12,000 lb',
        "Integrated fog light mounts accept factory or aftermarket pods"
      ],
      specs: [
        ["Material", "11-gauge CNC-cut steel plate"],
        ["Finish", "Textured black powder coat, e-coated"],
        ["Winch rating", "Up to 12,000 lb (synthetic or wire)"],
        ["Recovery points", "2 welded 3/8 in eyes, D-ring rated"],
        ["Warranty", "5 years structural, 1 year finish"]
      ]
    },
    "APX-LGT-UNIV-POD" => {
      features: [
        "Pair of 3-inch amber LED pods, SAE/DOT compliant for street use",
        "4,800 lumens per pair with a tight spot beam for long-range reach",
        "IP68 sealed housings survive pressure washing and deep water",
        "Includes stainless U-brackets, pigtail harness and switch kit"
      ],
      specs: [
        ["Light output", "4,800 lm per pair (raw)"],
        ["Beam pattern", "Spot, 12° with 8° flood insert included"],
        ["Rated current", "1.6 A @ 12.8 V per pod"],
        ["Ingress rating", "IP68 / IK08 impact rated"],
        ["Warranty", "3 years against defect and moisture"]
      ]
    },
    "APX-STRUT-G20-CF" => {
      features: [
        "Dry-carbon fiber strut tower brace cuts front chassis flex",
        "Billet aluminum ends with anodized finish and laser-etched logo",
        "Direct bolt-on for BMW G20 3-Series — no drilling or cutting",
        "Shaves turn-in lag under hard cornering; 30-second install"
      ],
      specs: [
        ["Material", "Dry-carbon fiber, autoclave cured"],
        ["Weight", "4.2 lb (1.9 kg)"],
        ["End fittings", "Billet 6061-T6, anodized"],
        ["Fitment", "BMW G20 330i / M340i 2019+"],
        ["Warranty", "Limited lifetime"]
      ]
    },
    "APX-OIL-KIT-0W20" => {
      features: [
        "Full-synthetic 0W-20 motor oil, API SP / ILSAC GF-6A rated",
        "OEM-spec spin-on filter with anti-drainback valve included",
        "Meets warranty requirements for modern turbo and hybrid engines",
        "Everything needed for one complete oil service in one box"
      ],
      specs: [
        ["Viscosity", "0W-20 full synthetic (5 US qt)"],
        ["Spec", "API SP / ILSAC GF-6A"],
        ["Filter", "OEM-spec spin-on included"],
        ["Change interval", "Up to 10,000 miles"],
        ["Warranty", "API-verified formulation"]
      ]
    },
    "APX-WIP-BLD-24" => {
      features: [
        "Beam-style blade hugs the windshield with no external frame",
        "Graphite-coated rubber for silent, streak-free wiping",
        "All-weather compound stays flexible from -40°F to 180°F",
        "Universal J-hook adapter, installs in under a minute per side"
      ],
      specs: [
        ["Sizes", "24 inch pair"],
        ["Style", "Beam blade, frameless"],
        ["Arm type", "J-hook (adapters included)"],
        ["Season", "All-weather, winter rated"],
        ["Warranty", "1 year against defect"]
      ]
    },
    "APX-BAT-AGM-H7" => {
      features: [
        "Absorbed Glass Mat (AGM) construction — spill-proof, vibration resistant",
        "800 cold-crank amps for confident winter starts on large-displacement engines",
        "Start-stop system ready with 2x cycle life vs flooded batteries",
        "Ships fully charged and ready to install"
      ],
      specs: [
        ["Group size", "H7 (48)"],
        ["Capacity", "80 Ah"],
        ["Cold crank amps", "800 CCA"],
        ["Technology", "AGM, start-stop ready"],
        ["Warranty", "4 years free replacement"]
      ]
    },
    "APX-CAB-AIR-TAC" => {
      features: [
        "Activated-carbon layer traps dust, pollen, exhaust odors and soot",
        "Restores HVAC airflow clogged by the factory filter",
        "Installs behind the glovebox — no tools, about 15 minutes",
        "Replace every 15,000 miles or yearly for best air quality"
      ],
      specs: [
        ["Media", "Activated carbon + particulate layer"],
        ["Fitment", "Tacoma 2016+, 4Runner 2010+"],
        ["Install time", "~15 minutes, no tools"],
        ["Interval", "15,000 miles / 12 months"],
        ["Warranty", "Fitment guaranteed"]
      ]
    },
    "APX-BRK-PAD-FRT" => {
      features: [
        "Ceramic compound — minimal brake dust, quiet operation",
        "Chamfered and slotted edges prevent squeal and taper wear",
        "Scorched backing plates seat in within the first few stops",
        "Hardware clips included for a complete front-axle service"
      ],
      specs: [
        ["Compound", "Ceramic, low-dust"],
        ["Position", "Front axle, 6-lug trucks"],
        ["Includes", "Shims, clips, hardware kit"],
        ["Pairs with", "APX-BRK-HD-TRK rotors"],
        ["Warranty", "2 years / 24,000 miles"]
      ]
    },
    "APX-SUSP-SHCK-JL" => {
      features: [
        "Twin-tube gas-charged design tuned for 2–3.5 inch lifted Jeep JL",
        "10-stage velocity-sensitive valving — soft on trail chatter, firm on-road",
        "Expanded reserve keeps performance through repeated off-road heat",
        "Sold as a front pair with all mounting hardware"
      ],
      specs: [
        ["Type", "Twin-tube gas shock, front pair"],
        ["Lift range", "2–3.5 inches"],
        ["Fitment", "Jeep Wrangler JL 2018+"],
        ["Valving", "10-stage velocity sensitive"],
        ["Warranty", "Limited lifetime (1 yr seal)"]
      ]
    },
    "APX-EXH-TIP-MST" => {
      features: [
        "Quad 4.5-inch burned-titanium finish — unique blue/gold heat coloring",
        "Clamp-on design fits stock or 2.75–3 inch aftermarket exhausts",
        "Double-wall rolled edge for a showroom-quality lip",
        "Full set of four with stainless band clamps included"
      ],
      specs: [
        ["Finish", "Burned titanium, double-wall"],
        ["Outlet", "4.5 inch quad set (4 pieces)"],
        ["Inlet", "2.75–3.0 inch clamp-on"],
        ["Fitment", "Mustang GT 2015+ valance cutouts"],
        ["Warranty", "Lifetime against finish defect"]
      ]
    },
    "APX-AIR-FIL-F150" => {
      features: [
        "Drops straight into the factory airbox — no tuning required",
        "Washable cotton gauze media flows more air than disposable paper",
        "Clean and re-oil every 50k miles; service life up to 100k",
        "Sealed polyurethane frame eliminates bypass leaks"
      ],
      specs: [
        ["Media", "Washable cotton gauze"],
        ["Fitment", "F-150 2015+ stock airbox, all engines"],
        ["Service interval", "Clean every 50,000 miles"],
        ["Install time", "~5 minutes, no tools"],
        ["Warranty", "10 years / 100,000 miles"]
      ]
    },
    "APX-LIN-UNIV-FLR" => {
      features: [
        "Rubberized composite liner with raised locking walls",
        "Trim-to-fit cutting guide — one SKU covers most vehicles",
        "Hoses clean; stays flexible from -40°F to 200°F",
        "Two rows included (driver + passenger + rear set)"
      ],
      specs: [
        ["Material", "Rubberized thermoplastic composite"],
        ["Coverage", "Front + rear rows (trim-to-fit)"],
        ["Cleanup", "Rinse with hose"],
        ["Temp range", "-40°F to 200°F"],
        ["Warranty", "Lifetime against cracking"]
      ]
    },
    "APX-TOW-HITCH-F150" => {
      features: [
        "SAE J684 Class IV rating — 12,000 lb GTW, 1,200 lb tongue",
        "2-inch receiver accepts ball mounts, bike racks and cargo carriers",
        "Bolt-on to factory mount points — no drilling or welding",
        "E-coated + powder-coated double finish resists road salt"
      ],
      specs: [
        ["Class", "IV (SAE J684)"],
        ["Receiver", "2 in square"],
        ["Rating", "12,000 lb GTW / 1,200 lb tongue"],
        ["Fitment", "F-150 2015+, factory mount points"],
        ["Warranty", "Lifetime structural"]
      ]
    },
    "APX-BRK-PAD-RR-4RN" => {
      features: [
        "Ceramic compound tuned for heavy-SUV rear-axle heat",
        "Shimmed backing plates eliminate squeal and rattle",
        "Chamfered edges prevent taper wear and uneven contact",
        "Complete hardware kit for a full rear-axle service"
      ],
      specs: [
        ["Compound", "Ceramic, low-dust"],
        ["Position", "Rear axle"],
        ["Fitment", "Toyota 4Runner 2010+"],
        ["Includes", "Shims and hardware kit"],
        ["Warranty", "2 years / 24,000 miles"]
      ]
    },
    "APX-CAI-MST-EB" => {
      features: [
        "Sealed airbox design pulls cool outside air, blocks engine heat",
        "Dyno-verified +12 hp / +16 lb-ft on the 2.3L EcoBoost",
        "No tune required — keeps the stock ECU calibration",
        "Washable conical filter, clean every 50k miles"
      ],
      specs: [
        ["Gains", "+12 hp / +16 lb-ft @ wheels"],
        ["Design", "Sealed airbox, rotomolded tube"],
        ["Filter", "Washable conical, 50k-mile service"],
        ["Fitment", "Mustang 2.3L EcoBoost 2015+"],
        ["Warranty", "Lifetime limited (filter: 1 year)"]
      ]
    },
    "APX-LGT-BAR-20-UNIV" => {
      features: [
        "14,400 raw lumens from 40 dual-row 5W LEDs",
        "Combo beam: center spot for reach, outer flood for spread",
        "IP68 die-cast aluminum housing with polycarbonate lens",
        "Plug-and-play relay harness with illuminated switch included"
      ],
      specs: [
        ["Light output", "14,400 lm (raw)"],
        ["Beam", "Combo (spot + flood)"],
        ["Length", "20 in dual-row"],
        ["Ingress", "IP68 sealed"],
        ["Warranty", "3 years against defect and moisture"]
      ]
    },
    "APX-SUSP-LFT-4RN-2IN" => {
      features: [
        "Billet 6061-T6 strut spacers — true 2-inch front level",
        "Keeps factory shocks and ride quality — no new hardware",
        "Clears up to 32-inch tires after alignment",
        "Anodized finish; install in 2–3 hours with hand tools"
      ],
      specs: [
        ["Lift", "2.0 in front level"],
        ["Material", "Billet 6061-T6, anodized"],
        ["Tire clearance", "Up to 32 in (alignment required)"],
        ["Fitment", "4Runner 2010+ (KDSS compatible)"],
        ["Warranty", "Limited lifetime"]
      ]
    },
    "APX-BED-MAT-TAC" => {
      features: [
        "Custom-molded for the Tacoma 5-ft bed — no trimming",
        "Nonslip ribs keep cargo from shifting and sliding",
        "High-density rubber withstands tools, pets and weather",
        "Rolls up for cleaning; won't trap water under the mat"
      ],
      specs: [
        ["Material", "High-density rubber, molded"],
        ["Fitment", "Tacoma 2016+ 5-ft bed"],
        ["Surface", "Nonslip rib pattern"],
        ["Cleanup", "Roll out and hose"],
        ["Warranty", "5 years against defect"]
      ]
    }
  }.freeze

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
