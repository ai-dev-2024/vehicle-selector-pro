# Seed file for Vehicle Selector Pro
puts "== Seeding Vehicle Selector Pro Database =="

# 1. Create Demo Shop (uses the configured store domain; falls back to the
#    bundled demo store so local development works out of the box)
demo_domain = ENV.fetch("SHOPIFY_STORE_DOMAIN", "vehicle-selector-pro.myshopify.com")
shop = Shop.find_or_create_by!(shopify_domain: demo_domain) do |s|
  s.shopify_token = "shpua_test_live_secret_token_12345"
  s.name = "Vehicle Selector Pro Demo"
  s.email = "support@vehicleselectorpro.example"
  s.currency = "USD"
  s.iana_timezone = "America/Detroit"
  s.active = true
end
puts "✓ Created Shop: #{shop.name} (#{shop.shopify_domain})"

# 2. Ensure App Settings
AppSetting.find_or_create_by!(shop: shop) do |settings|
  settings.widget_title = "Vehicle Fitment Finder"
  settings.widget_subtitle = "Select your vehicle to filter parts with 100% Fitment Guarantee"
  settings.layout_style = "horizontal"
  settings.primary_color = "#008060"
  settings.button_label = "Search My Vehicle"
  settings.reset_label = "Change Vehicle"
  settings.enable_trim = true
  settings.enable_engine = true
  settings.enable_garage = true
  settings.max_garage_vehicles = 5
  settings.auto_filter_collections = true
  settings.show_badge_on_product_page = true
end
puts "✓ Created Default App Settings for #{shop.shopify_domain}"

# 3. Seed Comprehensive Automotive YMMTE Vehicles
vehicles_data = [
  # Ford F-150 (2021-2024)
  { year: 2024, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD",
    body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "XLT", engine: "2.7L EcoBoost V6", drivetrain: "4WD",
    body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "Raptor", engine: "3.5L High-Output EcoBoost V6",
    drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "Platinum", engine: "5.0L Ti-VCT V8", drivetrain: "4WD",
    body_style: "SuperCrew" },
  { year: 2023, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD",
    body_style: "SuperCrew" },
  { year: 2023, make: "Ford", model: "F-150", trim: "XLT", engine: "5.0L Ti-VCT V8", drivetrain: "RWD",
    body_style: "SuperCab" },
  { year: 2022, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD",
    body_style: "SuperCrew" },
  { year: 2021, make: "Ford", model: "F-150", trim: "XLT", engine: "3.5L PowerBoost Full Hybrid V6", drivetrain: "4WD",
    body_style: "SuperCrew" },

  # Ford Mustang (2020-2024)
  { year: 2024, make: "Ford", model: "Mustang", trim: "GT Premium", engine: "5.0L Coyote V8", drivetrain: "RWD",
    body_style: "Fastback Coupe" },
  { year: 2024, make: "Ford", model: "Mustang", trim: "Dark Horse", engine: "5.0L Modified Coyote V8",
    drivetrain: "RWD", body_style: "Fastback Coupe" },
  { year: 2023, make: "Ford", model: "Mustang", trim: "EcoBoost", engine: "2.3L Turbocharged I4", drivetrain: "RWD",
    body_style: "Fastback Coupe" },
  { year: 2022, make: "Ford", model: "Mustang", trim: "Mach 1", engine: "5.0L Coyote V8", drivetrain: "RWD",
    body_style: "Fastback Coupe" },

  # Chevrolet Silverado 1500 (2021-2024)
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "LTZ", engine: "6.2L EcoTec3 V8", drivetrain: "4WD",
    body_style: "Crew Cab" },
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "RST", engine: "5.3L EcoTec3 V8", drivetrain: "4WD",
    body_style: "Crew Cab" },
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "ZR2", engine: "3.0L Duramax Turbo-Diesel I6",
    drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2023, make: "Chevrolet", model: "Silverado 1500", trim: "LT", engine: "2.7L TurboMax I4", drivetrain: "4WD",
    body_style: "Double Cab" },
  { year: 2022, make: "Chevrolet", model: "Silverado 1500", trim: "Custom", engine: "5.3L EcoTec3 V8",
    drivetrain: "RWD", body_style: "Crew Cab" },

  # Toyota Tacoma (2020-2024)
  { year: 2024, make: "Toyota", model: "Tacoma", trim: "TRD Off-Road", engine: "2.4L i-FORCE Turbo I4",
    drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2024, make: "Toyota", model: "Tacoma", trim: "TRD Pro", engine: "2.4L i-FORCE MAX Hybrid Turbo I4",
    drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2023, make: "Toyota", model: "Tacoma", trim: "TRD Sport", engine: "3.5L V6 DOHC", drivetrain: "4WD",
    body_style: "Access Cab" },
  { year: 2022, make: "Toyota", model: "Tacoma", trim: "SR5", engine: "3.5L V6 DOHC", drivetrain: "4WD",
    body_style: "Double Cab" },
  { year: 2021, make: "Toyota", model: "Tacoma", trim: "TRD Off-Road", engine: "3.5L V6 DOHC", drivetrain: "4WD",
    body_style: "Double Cab" },

  # Toyota 4Runner (2020-2024)
  { year: 2024, make: "Toyota", model: "4Runner", trim: "TRD Pro", engine: "4.0L 1GR-FE V6", drivetrain: "4WD",
    body_style: "SUV" },
  { year: 2023, make: "Toyota", model: "4Runner", trim: "TRD Off-Road Premium", engine: "4.0L 1GR-FE V6",
    drivetrain: "4WD", body_style: "SUV" },
  { year: 2022, make: "Toyota", model: "4Runner", trim: "Limited", engine: "4.0L 1GR-FE V6", drivetrain: "AWD",
    body_style: "SUV" },

  # Jeep Wrangler (2021-2024)
  { year: 2024, make: "Jeep", model: "Wrangler", trim: "Rubicon 392", engine: "6.4L HEMI V8", drivetrain: "4WD",
    body_style: "4-Door SUV" },
  { year: 2024, make: "Jeep", model: "Wrangler", trim: "Rubicon 4xe", engine: "2.0L Turbo PHEV I4", drivetrain: "4WD",
    body_style: "4-Door SUV" },
  { year: 2023, make: "Jeep", model: "Wrangler", trim: "Sahara", engine: "3.6L Pentastar V6 with eTorque",
    drivetrain: "4WD", body_style: "4-Door SUV" },
  { year: 2022, make: "Jeep", model: "Wrangler", trim: "Sport S", engine: "2.0L Turbocharged I4", drivetrain: "4WD",
    body_style: "2-Door SUV" },

  # BMW 3 Series (2021-2024)
  { year: 2024, make: "BMW", model: "3 Series", trim: "M340i xDrive", engine: "3.0L TwinPower Turbo B58 I6",
    drivetrain: "AWD", body_style: "Sedan" },
  { year: 2024, make: "BMW", model: "3 Series", trim: "330i", engine: "2.0L TwinPower Turbo B48 I4", drivetrain: "RWD",
    body_style: "Sedan" },
  { year: 2023, make: "BMW", model: "3 Series", trim: "M3 Competition", engine: "3.0L M TwinPower Turbo S58 I6",
    drivetrain: "AWD", body_style: "Sedan" },
  { year: 2022, make: "BMW", model: "3 Series", trim: "330e", engine: "2.0L TwinPower Turbo PHEV I4",
    drivetrain: "RWD", body_style: "Sedan" },

  # RAM 1500 (2022-2024)
  { year: 2024, make: "RAM", model: "1500", trim: "Laramie", engine: "5.7L HEMI V8 with eTorque",
    drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2024, make: "RAM", model: "1500", trim: "Big Horn", engine: "3.6L Pentastar V6",
    drivetrain: "4WD", body_style: "Quad Cab" },
  { year: 2023, make: "RAM", model: "1500", trim: "Rebel", engine: "5.7L HEMI V8",
    drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2022, make: "RAM", model: "1500", trim: "Limited", engine: "5.7L HEMI V8 with eTorque",
    drivetrain: "4WD", body_style: "Crew Cab" },

  # Honda Civic (2022-2024)
  { year: 2024, make: "Honda", model: "Civic", trim: "Sport", engine: "1.5L Turbocharged I4",
    drivetrain: "FWD", body_style: "Sedan" },
  { year: 2024, make: "Honda", model: "Civic", trim: "Si", engine: "1.5L Turbocharged High-Output I4",
    drivetrain: "FWD", body_style: "Sedan" },
  { year: 2023, make: "Honda", model: "Civic", trim: "Sport Touring", engine: "1.5L Turbocharged I4",
    drivetrain: "FWD", body_style: "Hatchback" },

  # Subaru Outback (2023-2024)
  { year: 2024, make: "Subaru", model: "Outback", trim: "Wilderness", engine: "2.4L Turbo BOXER I4",
    drivetrain: "AWD", body_style: "Wagon" },
  { year: 2023, make: "Subaru", model: "Outback", trim: "Limited", engine: "2.5L BOXER I4",
    drivetrain: "AWD", body_style: "Wagon" },

  # Ford Bronco (2023-2024)
  { year: 2024, make: "Ford", model: "Bronco", trim: "Badlands", engine: "2.7L EcoBoost V6",
    drivetrain: "4WD", body_style: "2-Door SUV" },
  { year: 2024, make: "Ford", model: "Bronco", trim: "Wildtrak", engine: "2.7L EcoBoost V6",
    drivetrain: "4WD", body_style: "4-Door SUV" },
  { year: 2023, make: "Ford", model: "Bronco", trim: "Outer Banks", engine: "2.3L EcoBoost I4",
    drivetrain: "4WD", body_style: "4-Door SUV" },

  # Older F-150 / Silverado years
  { year: 2020, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6",
    drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2020, make: "Ford", model: "F-150", trim: "XLT", engine: "5.0L Ti-VCT V8",
    drivetrain: "4WD", body_style: "SuperCab" },
  { year: 2020, make: "Chevrolet", model: "Silverado 1500", trim: "LT Trail Boss", engine: "5.3L EcoTec3 V8",
    drivetrain: "4WD", body_style: "Double Cab" }
]

vehicles = vehicles_data.map do |v_attrs|
  Vehicle.find_or_create_by!(
    year: v_attrs[:year],
    make: v_attrs[:make],
    model: v_attrs[:model],
    trim: v_attrs[:trim],
    engine: v_attrs[:engine]
  ) do |v|
    v.drivetrain = v_attrs[:drivetrain]
    v.body_style = v_attrs[:body_style]
    v.active = true
  end
end
puts "✓ Seeded #{vehicles.count} distinct Year/Make/Model/Trim/Engine vehicle configurations"

# 4. Seed Product Fitment Catalog
catalog_products = [
  {
    product_id: "gid://shopify/Product/10358752313620",
    product_handle: "apex-stage-2-cold-air-intake-ford-f150-ecoboost",
    product_title: "Apex Stage-2 Cold Air Intake System (Ford F-150 3.5L / 2.7L EcoBoost)",
    sku: "APX-CAI-F150-EB",
    brand: "Apex Performance",
    category: "Air Intake",
    price_cents: 34_900,
    short_description: "High-flow roto-molded intake with oiled cotton filter — sharper throttle response and a deeper induction note.",
    universal: false,
    fitment_notes: "Direct bolt-on replacement. Calibrated for 2.7L & 3.5L EcoBoost engines.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150").where("engine LIKE ?", "%EcoBoost%")
  },
  {
    product_id: "gid://shopify/Product/10358754017556",
    product_handle: "apex-pro-heavy-duty-brake-pad-rotor-kit-truck",
    product_title: "Apex Pro Severe-Duty Drilled & Slotted Brake Kit (Front Axle)",
    sku: "APX-BRK-HD-TRK",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 48_900,
    short_description: "Severe-duty drilled & slotted rotors with carbon-ceramic pads — shorter stops, less fade under towing loads.",
    universal: false,
    fitment_notes: "Front axle only. Fits 6-lug wheel hubs on F-150, Silverado 1500 and RAM 1500.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: %w[Ford Chevrolet RAM],
                                     model: ["F-150", "Silverado 1500", "1500"])
  },
  {
    product_id: "gid://shopify/Product/10358754050324",
    product_handle: "apex-baja-3-inch-suspension-lift-kit-tacoma",
    product_title: "Apex Baja 3-Inch Coilovers & Billet Control Arm Lift System",
    sku: "APX-SUSP-TACO-3IN",
    brand: "Apex Performance",
    category: "Suspension",
    price_cents: 114_900,
    short_description: "Complete 3-inch lift: tuned coilovers, billet upper control arms and extended travel — levels stance, clears 33s.",
    universal: false,
    fitment_notes: "Compatible with 4WD models. Clears up to 33-inch tires with zero rub.",
    position: "Front & Rear Suspension",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma", drivetrain: "4WD")
  },
  {
    product_id: "gid://shopify/Product/10358754083092",
    product_handle: "apex-stealth-stainless-cat-back-exhaust-v8",
    product_title: "Apex Stealth 3-Inch Dual Stainless Cat-Back Exhaust (Coyote V8)",
    sku: "APX-EXH-MUST-V8",
    brand: "Apex Performance",
    category: "Exhaust",
    price_cents: 89_900,
    short_description: "3-inch mandrel-bent stainless cat-back with active valves — aggressive under load, civilized at cruise.",
    universal: false,
    fitment_notes: "Engineered for 5.0L Coyote V8 engines with active valve control.",
    position: "Exhaust / Undercarriage",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang").where("engine LIKE ?", "%Coyote%")
  },
  {
    product_id: "gid://shopify/Product/10358754115860",
    product_handle: "apex-rock-crawler-front-bumper-jeep-wrangler",
    product_title: "Apex Armor Rock-Crawler High-Clearance Winch Front Bumper",
    sku: "APX-BMP-JL-001",
    brand: "Apex Armor",
    category: "Bumpers & Armor",
    price_cents: 74_900,
    short_description: "High-clearance steel winch bumper with welded recovery points and integrated fog light mounts.",
    universal: false,
    fitment_notes: "Fits all JL Wrangler models. Accommodates up to 12,000 lb winches.",
    position: "Front Bumper",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
  },
  {
    product_id: "gid://shopify/Product/10358754148628",
    product_handle: "apex-universal-high-output-led-fog-pod-kit",
    product_title: "Apex UltraBeam 3-Inch Amber SAE/DOT High-Output LED Pods (Universal)",
    sku: "APX-LGT-UNIV-POD",
    brand: "Apex Lighting",
    category: "Lighting",
    price_cents: 18_900,
    short_description: "3-inch SAE/DOT street-legal amber LED pods, 4,800 lm per pair, " \
                       "IP68 sealed — mounts anywhere with included brackets.",
    universal: true,
    fitment_notes: "Universal fitment. Includes multi-fit brackets and waterproof DT wiring harness.",
    position: "Auxiliary / Universal",
    matching_vehicles: []
  },
  {
    product_id: "gid://shopify/Product/10358754181396",
    product_handle: "apex-carbon-fiber-strut-tower-brace-bmw",
    product_title: "Apex RaceWerks Carbon Fiber Chassis Strut Tower Brace (BMW G20 3-Series)",
    sku: "APX-STRUT-G20-CF",
    brand: "Apex RaceWerks",
    category: "Chassis & Handling",
    price_cents: 32_900,
    short_description: "Dry-carbon strut tower brace — sharpens turn-in and cuts front-end flex without adding weight.",
    universal: false,
    fitment_notes: "Fits G20 3-Series chassis (330i, M340i, M3). Enhances front-end torsional rigidity.",
    position: "Front Strut Towers",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  },

  # ---- Расширенный каталог: расходники и ТО (Maintenance / Filters / Electrical) ----
  {
    product_id: "gid://shopify/Product/10358754214001",
    product_handle: "apex-full-synthetic-oil-change-kit-0w20",
    product_title: "Apex Full-Synthetic Oil Change Kit 0W-20 (5 qt + OEM filter)",
    sku: "APX-OIL-KIT-0W20",
    brand: "Apex Performance",
    category: "Maintenance",
    price_cents: 8900,
    short_description: "Full-synthetic 0W-20 API SP kit with OEM-spec filter — everything for a proper oil service.",
    universal: true,
    fitment_notes: "Universal for vehicles specifying 0W-20. Check your owner's manual.",
    position: "Engine / Service",
    matching_vehicles: []
  },
  {
    product_id: "gid://shopify/Product/10358754214002",
    product_handle: "apex-all-season-wiper-blades-24in",
    product_title: "Apex ClearView All-Season Wiper Blades 24\" (pair)",
    sku: "APX-WIP-BLD-24",
    brand: "Apex ClearView",
    category: "Wipers & Visibility",
    price_cents: 3900,
    short_description: "Beam-style all-season wipers with graphite-coated rubber — silent, streak-free wipe.",
    universal: true,
    fitment_notes: "Universal J-hook arm fitment, 24 inch pair. Adapters included.",
    position: "Windshield",
    matching_vehicles: []
  },
  {
    product_id: "gid://shopify/Product/10358754214003",
    product_handle: "apex-agm-battery-h7-48",
    product_title: "Apex PowerCell AGM Battery H7 (48) 80Ah 800CCA",
    sku: "APX-BAT-AGM-H7",
    brand: "Apex PowerCell",
    category: "Electrical",
    price_cents: 21_900,
    short_description: "AGM battery with 800 cold-crank amps — start-stop ready, vibration resistant, 4-year warranty.",
    universal: false,
    fitment_notes: "Group H7/48. Fits F-150, Silverado 1500, RAM 1500 and most full-size trucks.",
    position: "Engine Bay / Battery Tray",
    matching_vehicles: Vehicle.where(make: %w[Ford Chevrolet RAM],
                                     model: ["F-150", "Silverado 1500", "1500"])
  },
  {
    product_id: "gid://shopify/Product/10358754214004",
    product_handle: "apex-cabin-air-filter-toyota",
    product_title: "Apex FreshAir Cabin Air Filter (Toyota Tacoma / 4Runner)",
    sku: "APX-CAB-AIR-TAC",
    brand: "Apex FreshAir",
    category: "Filters",
    price_cents: 2400,
    short_description: "Activated-carbon cabin filter — blocks dust, pollen and odors. 15-minute DIY swap.",
    universal: false,
    fitment_notes: "Fits Toyota Tacoma (2016+) and 4Runner (2010+).",
    position: "HVAC / Behind Glovebox",
    matching_vehicles: Vehicle.where(make: "Toyota", model: %w[Tacoma 4Runner])
  },
  {
    product_id: "gid://shopify/Product/10358754214005",
    product_handle: "apex-ceramic-front-brake-pads",
    product_title: "Apex QuietStop Ceramic Front Brake Pads (Truck/SUV)",
    sku: "APX-BRK-PAD-FRT",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 7900,
    short_description: "Low-dust ceramic pads with chamfered edges and slots — quiet stops without rotor wear.",
    universal: false,
    fitment_notes: "Front axle, 6-lug trucks. Pairs with APX-BRK-HD-TRK rotors.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: %w[Ford Chevrolet], model: ["F-150", "Silverado 1500"])
  },
  {
    product_id: "gid://shopify/Product/10358754214006",
    product_handle: "apex-front-shocks-jeep-wrangler-jl",
    product_title: "Apex TrailRunner Front Shocks (Jeep Wrangler JL, pair)",
    sku: "APX-SUSP-SHCK-JL",
    brand: "Apex TrailRunner",
    category: "Suspension",
    price_cents: 24_900,
    short_description: "Twin-tube gas shocks tuned for 2–3.5 inch lift — comfortable on-road, planted off-road.",
    universal: false,
    fitment_notes: "Front pair, Jeep Wrangler JL (2018+). Fits lifted and stock suspensions.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
  },
  {
    product_id: "gid://shopify/Product/10358754214007",
    product_handle: "apex-burned-titanium-exhaust-tips-mustang",
    product_title: "Apex Burned-Titanium Quad Exhaust Tips (Mustang GT, set of 4)",
    sku: "APX-EXH-TIP-MST",
    brand: "Apex Performance",
    category: "Exhaust",
    price_cents: 14_900,
    short_description: "Quad 4.5-inch burned-titanium tips — showroom finish over stock or aftermarket exhausts.",
    universal: false,
    fitment_notes: "Fits Mustang GT (2015+) rear valance cutouts. Clamp-on install.",
    position: "Rear Valance",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang")
  },
  {
    product_id: "gid://shopify/Product/10358754214008",
    product_handle: "apex-high-flow-engine-air-filter-f150",
    product_title: "Apex High-Flow Washable Engine Air Filter (F-150 2.7L/3.5L/5.0L)",
    sku: "APX-AIR-FIL-F150",
    brand: "Apex Performance",
    category: "Filters",
    price_cents: 5900,
    short_description: "Washable high-flow cotton-gauze filter — drops in the stock airbox, lasts 100k miles.",
    universal: false,
    fitment_notes: "Fits F-150 (2015+) stock airbox, all engines. Washable, no oiling mess.",
    position: "Engine Bay / Airbox",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150")
  },

  # ---- Расширенный каталог 2: интерьер, буксировка, вторая волна ТО ----
  {
    product_id: "gid://shopify/Product/10358754214009",
    product_handle: "apex-trailguard-floor-liners-universal",
    product_title: "Apex TrailGuard Trim-to-Fit All-Weather Floor Liners (2 rows)",
    sku: "APX-LIN-UNIV-FLR",
    brand: "Apex TrailGuard",
    category: "Interior & Comfort",
    price_cents: 6900,
    short_description: "Rubberized trim-to-fit liners with raised walls — traps slush, mud and spills, hoses clean.",
    universal: true,
    fitment_notes: "Trim-to-fit for most cars, trucks and SUVs. Cutting guide printed on liner.",
    position: "Floor / Interior",
    matching_vehicles: []
  },
  {
    product_id: "gid://shopify/Product/10358754214010",
    product_handle: "apex-towmaster-class4-hitch-f150",
    product_title: "Apex TowMaster Class IV Trailer Hitch Receiver (Ford F-150)",
    sku: "APX-TOW-HITCH-F150",
    brand: "Apex TowMaster",
    category: "Towing",
    price_cents: 24_900,
    short_description: "2-inch Class IV receiver, 12,000 lb GTW / 1,200 lb tongue — bolt-on with factory hardware.",
    universal: false,
    fitment_notes: "Fits F-150 (2015+). Uses factory mount points, no drilling. Pin & clip included.",
    position: "Rear Chassis",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150")
  },
  {
    product_id: "gid://shopify/Product/10358754214011",
    product_handle: "apex-quietstop-rear-pads-4runner",
    product_title: "Apex QuietStop Ceramic Rear Brake Pads (Toyota 4Runner)",
    sku: "APX-BRK-PAD-RR-4RN",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 6900,
    short_description: "Low-dust ceramic rear pads with shims — quiet, even wear for heavy SUVs.",
    universal: false,
    fitment_notes: "Rear axle, 4Runner (2010+). Hardware kit included.",
    position: "Rear Axle",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214012",
    product_handle: "apex-stage1-cai-mustang-ecoboost",
    product_title: "Apex Stage-1 Cold Air Intake (Mustang 2.3L EcoBoost)",
    sku: "APX-CAI-MST-EB",
    brand: "Apex Performance",
    category: "Air Intake",
    price_cents: 29_900,
    short_description: "Sealed airbox intake with washable filter — +12 hp on the 2.3L EcoBoost, no tune required.",
    universal: false,
    fitment_notes: "Fits Mustang 2.3L EcoBoost (2015+). CARB-pending; keeps stock ECU calibration.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang").where("engine LIKE ?", "%2.3L%")
  },
  {
    product_id: "gid://shopify/Product/10358754214013",
    product_handle: "apex-ultrabeam-20in-light-bar-universal",
    product_title: "Apex UltraBeam 20-Inch Dual-Row LED Light Bar (Universal)",
    sku: "APX-LGT-BAR-20-UNIV",
    brand: "Apex Lighting",
    category: "Lighting",
    price_cents: 12_900,
    short_description: "14,400 lm combo-beam light bar with IP68 housing, wiring harness and switch included.",
    universal: true,
    fitment_notes: "Universal mounts: bumpers, racks, grilles. Relay harness + switch included.",
    position: "Auxiliary / Universal",
    matching_vehicles: []
  },
  {
    product_id: "gid://shopify/Product/10358754214014",
    product_handle: "apex-trailrunner-leveling-kit-4runner",
    product_title: "Apex TrailRunner 2-Inch Front Leveling Kit (Toyota 4Runner)",
    sku: "APX-SUSP-LFT-4RN-2IN",
    brand: "Apex TrailRunner",
    category: "Suspension",
    price_cents: 14_900,
    short_description: "Billet strut spacers level the nose, clears 32-inch tires — keeps factory ride quality.",
    universal: false,
    fitment_notes: "Fits 4Runner (2010+). Front strut spacers, anodized 6061-T6. No new shocks needed.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214015",
    product_handle: "apex-trailbed-rubber-bed-mat-tacoma",
    product_title: "Apex TrailBed Rubber Bed Mat (Toyota Tacoma 5-ft bed)",
    sku: "APX-BED-MAT-TAC",
    brand: "Apex TrailBed",
    category: "Interior & Comfort",
    price_cents: 18_900,
    short_description: "Heavy rubber bed mat with nonslip ribs — protects the bed and keeps cargo from sliding.",
    universal: false,
    fitment_notes: "Fits Tacoma (2016+) 5-ft bed. Custom-molded, no trimming required.",
    position: "Truck Bed",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma")
  },

  # ---- Каталог волна 3: RAM, Honda, Subaru, Bronco, Silverado ----
  {
    product_id: "gid://shopify/Product/10358754214016",
    product_handle: "apex-airraid-cai-ram-hemi",
    product_title: "Apex AirRaid Cold Air Intake (RAM 1500 5.7L HEMI)",
    sku: "APX-CAI-RAM-V8",
    brand: "Apex Performance",
    category: "Air Intake",
    price_cents: 31_900,
    short_description: "Rotomolded intake with washable filter — sharper HEMI throttle response and a deeper growl.",
    universal: false,
    fitment_notes: "Fits RAM 1500 5.7L HEMI (2019+, incl. eTorque). No tune required.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "RAM", model: "1500").where("engine LIKE ?", "%5.7L HEMI%")
  },
  {
    product_id: "gid://shopify/Product/10358754214017",
    product_handle: "apex-stealth-catback-ram-hemi",
    product_title: "Apex Stealth 2.75-Inch Stainless Cat-Back Exhaust (RAM 1500 HEMI)",
    sku: "APX-EXH-RAM-V8",
    brand: "Apex Performance",
    category: "Exhaust",
    price_cents: 74_900,
    short_description: "Mandrel-bent T-304 stainless cat-back with aggressive-but-civilized turbo mufflers.",
    universal: false,
    fitment_notes: "Fits RAM 1500 5.7L HEMI (2019+). Bolts to factory flanges, keeps rear sensors.",
    position: "Exhaust / Undercarriage",
    matching_vehicles: Vehicle.where(make: "RAM", model: "1500").where("engine LIKE ?", "%5.7L HEMI%")
  },
  {
    product_id: "gid://shopify/Product/10358754214018",
    product_handle: "apex-trailrunner-leveling-ram-25",
    product_title: "Apex TrailRunner 2.5-Inch Leveling Kit (RAM 1500 4WD)",
    sku: "APX-SUSP-LFT-RAM-25",
    brand: "Apex TrailRunner",
    category: "Suspension",
    price_cents: 15_900,
    short_description: "Billet strut spacers level the RAM's factory rake and clear 35-inch tires.",
    universal: false,
    fitment_notes: "Fits RAM 1500 4WD (2019+). Front spacers only; alignment required.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "RAM", model: "1500", drivetrain: "4WD")
  },
  {
    product_id: "gid://shopify/Product/10358754214019",
    product_handle: "apex-short-ram-intake-civic-15t",
    product_title: "Apex RaceWerks Short-Ram Intake (Honda Civic 1.5L Turbo)",
    sku: "APX-CAI-CIV-15T",
    brand: "Apex RaceWerks",
    category: "Air Intake",
    price_cents: 24_900,
    short_description: "Heat-shielded short-ram with dry filter — +9 hp on the 1.5T, install in an afternoon.",
    universal: false,
    fitment_notes: "Fits Civic 1.5L Turbo (2016+, Sedan/Hatchback/Si). No tune required.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Honda", model: "Civic")
  },
  {
    product_id: "gid://shopify/Product/10358754214020",
    product_handle: "apex-racewerks-lowering-springs-civic",
    product_title: "Apex RaceWerks Progressive Lowering Springs (Honda Civic 1.5T)",
    sku: "APX-CHP-SPR-CIV",
    brand: "Apex RaceWerks",
    category: "Chassis & Handling",
    price_cents: 27_900,
    short_description: "Progressive-rate springs drop 1.2 in front / 1.0 in rear — sharper corners, comfortable daily ride.",
    universal: false,
    fitment_notes: "Fits Civic Sedan/Hatchback 1.5T (2016+) incl. Si. Keeps stock shocks within travel limits.",
    position: "Front & Rear Springs",
    matching_vehicles: Vehicle.where(make: "Honda", model: "Civic")
  },
  {
    product_id: "gid://shopify/Product/10358754214021",
    product_handle: "apex-trailguard-crossbars-outback",
    product_title: "Apex TrailGuard Aero Crossbars (Subaru Outback)",
    sku: "APX-EXT-RACK-OUT",
    brand: "Apex TrailGuard",
    category: "Exterior & Racks",
    price_cents: 32_900,
    short_description: "Low-profile aero crossbars rated 165 lb — mounts boxes, bikes and kayaks without wind whistle.",
    universal: false,
    fitment_notes: "Fits Outback (2020+) factory fixed points. Load-rated 165 lb dynamic.",
    position: "Roof Rails",
    matching_vehicles: Vehicle.where(make: "Subaru", model: "Outback")
  },
  {
    product_id: "gid://shopify/Product/10358754214022",
    product_handle: "apex-quietstop-pads-outback",
    product_title: "Apex QuietStop Ceramic Brake Pads (Subaru Outback, front + rear)",
    sku: "APX-BRK-PAD-OUT",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 8_900,
    short_description: "Front and rear ceramic pad set with hardware — quiet, low-dust stops for a loaded wagon.",
    universal: false,
    fitment_notes: "Fits Outback (2015+), front and rear axles. Hardware included.",
    position: "Front & Rear Axles",
    matching_vehicles: Vehicle.where(make: "Subaru", model: "Outback")
  },
  {
    product_id: "gid://shopify/Product/10358754214023",
    product_handle: "apex-stage2-cai-bronco-27",
    product_title: "Apex Stage-2 Cold Air Intake (Ford Bronco 2.7L EcoBoost)",
    sku: "APX-CAI-BRN-27",
    brand: "Apex Performance",
    category: "Air Intake",
    price_cents: 34_900,
    short_description: "High-flow sealed intake for the 2.7L EcoBoost — +14 hp, water-resistant for trail crossings.",
    universal: false,
    fitment_notes: "Fits Bronco 2.7L EcoBoost (2021+). Hydro-shield prefilter included.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Bronco").where("engine LIKE ?", "%2.7L EcoBoost%")
  },
  {
    product_id: "gid://shopify/Product/10358754214024",
    product_handle: "apex-ultrabeam-pod-kit-bronco",
    product_title: "Apex UltraBeam 6-Pod Roof Light Kit (Ford Bronco)",
    sku: "APX-LGT-POD-BRN",
    brand: "Apex Lighting",
    category: "Lighting",
    price_cents: 24_900,
    short_description: "Six 3-inch pods on a roof-mount plate — 14,400 lm of trail lighting with hidden wiring channels.",
    universal: false,
    fitment_notes: "Fits Bronco (2021+) factory roof rack rails. Harness and switch included.",
    position: "Roof Rack",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Bronco")
  },
  {
    product_id: "gid://shopify/Product/10358754214025",
    product_handle: "apex-towmaster-hitch-silverado",
    product_title: "Apex TowMaster Class IV Trailer Hitch (Chevrolet Silverado 1500)",
    sku: "APX-TOW-HITCH-SLV",
    brand: "Apex TowMaster",
    category: "Towing",
    price_cents: 24_900,
    short_description: "2-inch Class IV receiver, 12,000 lb GTW — bolt-on with factory mount points and hardware.",
    universal: false,
    fitment_notes: "Fits Silverado 1500 (2014+). Pin & clip included; no drilling.",
    position: "Rear Chassis",
    matching_vehicles: Vehicle.where(make: "Chevrolet", model: "Silverado 1500")
  },
  {
    product_id: "gid://shopify/Product/10358754214026",
    product_handle: "apex-slotted-front-rotors-mustang-gt",
    product_title: "Apex Pro Slotted Front Rotors (Mustang GT / Mach 1)",
    sku: "APX-BRK-ROT-MST",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 44_900,
    short_description: "Directionally slotted G3000 rotors for the Coyote GT — fade-resistant track-day braking.",
    universal: false,
    fitment_notes: "Fits Mustang 5.0L V8 (2015+). Sold as a pair; pads sold separately.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang").where("engine LIKE ?", "%5.0L%")
  },
  {
    product_id: "gid://shopify/Product/10358754214027",
    product_handle: "apex-trailrunner-rear-shocks-tacoma",
    product_title: "Apex TrailRunner Rear Shocks (Toyota Tacoma 4WD, pair)",
    sku: "APX-SUSP-SHCK-TAC",
    brand: "Apex TrailRunner",
    category: "Suspension",
    price_cents: 27_900,
    short_description: "Twin-tube gas rear shocks tuned for loaded trails — pairs with the Baja lift kit.",
    universal: false,
    fitment_notes: "Rear pair, Tacoma 4WD (2016+). Fits stock or lifted ride heights 0–3 in.",
    position: "Rear Suspension",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma", drivetrain: "4WD")
  },

  # ---- Catalog wave 4: maintenance, electrical, filtration & hardware ----
  {
    product_id: "gid://shopify/Product/10358754214028",
    product_handle: "apexflow-premium-oil-filter-pair-full-size-trucks",
    product_title: "ApexFlow Premium Oil Filter, Pair (Full-Size Trucks)",
    sku: "APX-OIL-FLT-TRK",
    brand: "ApexFlow",
    category: "Maintenance",
    price_cents: 2_900,
    short_description: "Synthetic-blend media captures 99% of contaminants down to 19 microns — sold as a pair for two services.",
    universal: false,
    fitment_notes: "Fits Ford F-150 5.0L V8, Chevrolet Silverado 1500 V8 and RAM 1500 5.7L HEMI. Pair covers two oil changes.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150").where("engine LIKE ?", "%5.0L%")
                              .or(Vehicle.where(make: "Chevrolet", model: "Silverado 1500").where("engine LIKE ?", "%V8%"))
                              .or(Vehicle.where(make: "RAM", model: "1500").where("engine LIKE ?", "%HEMI%"))
  },
  {
    product_id: "gid://shopify/Product/10358754214029",
    product_handle: "apexcool-long-life-coolant-concentrate-1-gallon",
    product_title: "ApexCool Long-Life Coolant Concentrate, 1 Gallon",
    sku: "APX-CLT-LLC-1GL",
    brand: "ApexCool",
    category: "Maintenance",
    price_cents: 2_400,
    short_description: "OAT organic-acid coolant concentrate.",
    universal: true,
    fitment_notes: "Universal — mix 50/50 with distilled water. Compatible with all gasoline and turbo-diesel engines.",
    position: "Cooling System"
  },
  {
    product_id: "gid://shopify/Product/10358754214030",
    product_handle: "apexfire-iridium-spark-plug-set-8-piece-v8-trucks",
    product_title: "ApexFire Iridium Spark Plug Set, 8-Piece (V8 Trucks)",
    sku: "APX-SPK-IR-V8",
    brand: "ApexFire",
    category: "Maintenance",
    price_cents: 6_800,
    short_description: "0.6mm iridium center electrodes for a stronger, more consistent spark — smoother idle and easier cold starts.",
    universal: false,
    fitment_notes: "8-pc set for Ford F-150 5.0L V8, Chevrolet Silverado 1500 5.3L/6.2L V8 and RAM 1500 5.7L HEMI.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150").where("engine LIKE ?", "%5.0L%")
                              .or(Vehicle.where(make: "Chevrolet", model: "Silverado 1500").where("engine LIKE ?", "%V8%"))
                              .or(Vehicle.where(make: "RAM", model: "1500").where("engine LIKE ?", "%HEMI%"))
  },
  {
    product_id: "gid://shopify/Product/10358754214031",
    product_handle: "apexfire-ignition-coil-pack-6-piece-toyota-4-0l",
    product_title: "ApexFire Ignition Coil Pack, 6-Piece (Toyota 4.0L 1GR-FE)",
    sku: "APX-IGN-COIL-GRF6",
    brand: "ApexFire",
    category: "Maintenance",
    price_cents: 14_700,
    short_description: "High-output coil-on-plug set wound for faster rise times.",
    universal: false,
    fitment_notes: "6-pc set for Toyota 4.0L 1GR-FE V6: 4Runner (all trims) and Tacoma 3.5L V6.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
                              .or(Vehicle.where(make: "Toyota", model: "Tacoma").where("engine LIKE ?", "%V6%"))
  },
  {
    product_id: "gid://shopify/Product/10358754214032",
    product_handle: "apexdrive-serpentine-belt-ford-f150-3-5l-ecoboost",
    product_title: "ApexDrive Serpentine Belt (Ford F-150 3.5L EcoBoost)",
    sku: "APX-SERP-BLT-F150",
    brand: "ApexDrive",
    category: "Maintenance",
    price_cents: 4_500,
    short_description: "EPDM construction with aramid-reinforced cords — quiet, crack-resistant and rated for 150k miles of turbo duty.",
    universal: false,
    fitment_notes: "Exact-fit belt for F-150 3.5L EcoBoost (2011+), including Raptor high-output.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150").where("engine LIKE ?", "%3.5L%")
  },
  {
    product_id: "gid://shopify/Product/10358754214033",
    product_handle: "apexflow-throttle-body-intake-valve-cleaner-kit",
    product_title: "ApexFlow Throttle-Body & Intake Valve Cleaner Kit",
    sku: "APX-THRB-CLN-KIT",
    brand: "ApexFlow",
    category: "Maintenance",
    price_cents: 2_200,
    short_description: "Two-step kit strips carbon from throttle plates and direct-injection intake valves.",
    universal: true,
    fitment_notes: "Universal — safe for port and direct injection, turbo and naturally-aspirated engines.",
    position: "Engine Bay"
  },
  {
    product_id: "gid://shopify/Product/10358754214034",
    product_handle: "apexvolt-240a-high-output-alternator-jeep-wrangler",
    product_title: "ApexVolt 240A High-Output Alternator (Jeep Wrangler)",
    sku: "APX-ALT-240A-WRK",
    brand: "ApexVolt",
    category: "Electrical",
    price_cents: 36_900,
    short_description: "240-amp output feeds light bars, winches and compressors without dimming the headlights at idle.",
    universal: false,
    fitment_notes: "Direct-fit for Jeep Wrangler JL/JLU 3.6L V6 and 2.0L turbo (2018+). Includes clutch pulley.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
  },
  {
    product_id: "gid://shopify/Product/10358754214035",
    product_handle: "apexvolt-gear-reduction-starter-toyota-4runner-4-0l",
    product_title: "ApexVolt Gear-Reduction Starter Motor (Toyota 4Runner 4.0L)",
    sku: "APX-STA-GR-4RN",
    brand: "ApexVolt",
    category: "Electrical",
    price_cents: 16_800,
    short_description: "Gear-reduction design spins harder while drawing less current — confident starts on cold mornings.",
    universal: false,
    fitment_notes: "Direct-fit for Toyota 4Runner 4.0L V6 (2010+). Copper-wound, new — not remanufactured.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214036",
    product_handle: "apexvolt-dual-battery-isolation-kit-smart-acr",
    product_title: "ApexVolt Dual-Battery Isolation Kit with Smart ACR",
    sku: "APX-DUAL-BAT-KIT",
    brand: "ApexVolt",
    category: "Electrical",
    price_cents: 21_500,
    short_description: "Voltage-sensing relay parallels batteries only when the alternator is charging.",
    universal: true,
    fitment_notes: "Universal — fits any 12V negative-ground vehicle. Includes ACR, cabling, lugs and mounting hardware.",
    position: "Engine Bay"
  },
  {
    product_id: "gid://shopify/Product/10358754214037",
    product_handle: "apexclear-all-season-beam-wiper-blades-22-pair",
    product_title: "ApexClear All-Season Beam Wiper Blades, 22\"/22\" Pair",
    sku: "APX-WIP-BLD-22PR",
    brand: "ApexClear",
    category: "Wipers & Visibility",
    price_cents: 3_400,
    short_description: "Beam-blade design hugs curved windshields with even pressure — silent, streak-free sweeps down to -40°.",
    universal: true,
    fitment_notes: "Universal 22\"/22\" pair with multi-adapter arm. Check the fitment widget for adapter type per vehicle.",
    position: "Front Windshield"
  },
  {
    product_id: "gid://shopify/Product/10358754214038",
    product_handle: "apexpure-activated-charcoal-cabin-filter-bmw-3-series",
    product_title: "ApexPure Activated-Charcoal Cabin Filter (BMW 3 Series)",
    sku: "APX-CAB-AIR-BMW",
    brand: "ApexPure",
    category: "Filters",
    price_cents: 2_900,
    short_description: "Activated-charcoal layer traps diesel soot, pollen and odors — restores that new-car cabin smell in minutes.",
    universal: false,
    fitment_notes: "Cabin-intake filter for BMW 3 Series G20 (2019+), all engines. 10-minute glovebox install.",
    position: "Cabin",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  },
  {
    product_id: "gid://shopify/Product/10358754214039",
    product_handle: "apexstop-low-dust-ceramic-brake-pad-set-front-bmw-3-series",
    product_title: "ApexStop Low-Dust Ceramic Brake Pad Set, Front (BMW 3 Series)",
    sku: "APX-BRK-PAD-BMW",
    brand: "ApexStop",
    category: "Brakes",
    price_cents: 9_900,
    short_description: "Ceramic compound keeps wheels noticeably cleaner while delivering the progressive bite BMW brakes are known for.",
    universal: false,
    fitment_notes: "Front axle, BMW 3 Series G20 330i and M340i (2019+). Hardware kit included.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  },
  {
    product_id: "gid://shopify/Product/10358754214040",
    product_handle: "apexgrip-front-sway-bar-26mm-honda-civic",
    product_title: "ApexGrip Front Sway Bar, 26mm (Honda Civic)",
    sku: "APX-SWAY-BAR-CIV",
    brand: "ApexGrip",
    category: "Chassis & Handling",
    price_cents: 24_900,
    short_description: "26mm hollow-formed bar with two adjustment positions — flattens body roll without punishing ride quality.",
    universal: false,
    fitment_notes: "Honda Civic FE (2022+), Sedan and Hatchback. Includes polyurethane bushings and end links.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "Honda", model: "Civic")
  },
  {
    product_id: "gid://shopify/Product/10358754214041",
    product_handle: "apexdrive-heavy-duty-cv-axle-assembly-toyota-tacoma-4wd",
    product_title: "ApexDrive Heavy-Duty CV Axle Assembly, Front (Toyota Tacoma 4WD)",
    sku: "APX-CV-AXLE-TAC",
    brand: "ApexDrive",
    category: "Chassis & Handling",
    price_cents: 13_900,
    short_description: "Over-center plunge CV joints tolerate lifted angles stock axles can't.",
    universal: false,
    fitment_notes: "Front axle, Tacoma 4WD (2016+). Rated for lifts up to 3 inches.",
    position: "Front Drivetrain",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma", drivetrain: "4WD")
  },
  {
    product_id: "gid://shopify/Product/10358754214042",
    product_handle: "apexstop-front-brake-caliper-rebuild-kit-full-size-trucks",
    product_title: "ApexStop Front Brake Caliper Rebuild Kit (Full-Size Trucks)",
    sku: "APX-CAL-RBLD-TRK",
    brand: "ApexStop",
    category: "Brakes",
    price_cents: 3_600,
    short_description: "Seals, dust boots and bleed screws bring tired calipers back to like-new clamping — one kit per axle.",
    universal: false,
    fitment_notes: "Front calipers on F-150, Silverado 1500 and RAM 1500 (2019+). EPDM seals, high-temp grease included.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150")
                              .or(Vehicle.where(make: "Chevrolet", model: "Silverado 1500"))
                              .or(Vehicle.where(make: "RAM", model: "1500"))
  },
  {
    product_id: "gid://shopify/Product/10358754214043",
    product_handle: "apexcomfort-neoprene-seat-covers-front-row-toyota-tacoma",
    product_title: "ApexComfort Neoprene Seat Covers, Front Row (Toyota Tacoma)",
    sku: "APX-SEAT-CVR-TAC",
    brand: "ApexComfort",
    category: "Interior & Comfort",
    price_cents: 18_900,
    short_description: "4mm padded neoprene shrugs off wet swimsuits, mud and dog claws — custom-tailored for Tacoma seats, airbag-safe.",
    universal: false,
    fitment_notes: "Front row, Tacoma Double Cab and Access Cab (2016+). Side-airbag compatible stitching.",
    position: "Cabin",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma")
  },
  {
    product_id: "gid://shopify/Product/10358754214044",
    product_handle: "apexshield-mud-flap-set-front-rear-toyota-4runner",
    product_title: "ApexShield Mud Flap Set, Front & Rear (Toyota 4Runner)",
    sku: "APX-MUD-FLP-4RN",
    brand: "ApexShield",
    category: "Exterior & Racks",
    price_cents: 7_400,
    short_description: "Weighted rubber flaps with stainless brackets stop gravel rash on paint, rockers and whatever's towing behind you.",
    universal: false,
    fitment_notes: "4-Piece set, Toyota 4Runner (2010+). No-drill, bolts to factory mounting points.",
    position: "Exterior",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214045",
    product_handle: "apexarmor-12000-lb-electric-winch-synthetic-rope",
    product_title: "ApexArmor 12,000-lb Electric Winch with Synthetic Rope",
    sku: "APX-WINCH-12K",
    brand: "ApexArmor",
    category: "Bumpers & Armor",
    price_cents: 49_900,
    short_description: "12,000-lb pull, 94 ft of plasma rope and a wireless remote — self-recovery strength in a sealed IP68 housing.",
    universal: false,
    fitment_notes: "Fits standard 10x4.5 winch-mount bumpers: Jeep Wrangler, F-150, Silverado 1500, RAM 1500, Tacoma, 4Runner.",
    position: "Front Bumper",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
                              .or(Vehicle.where(make: "Ford", model: %w[F-150 Bronco]))
                              .or(Vehicle.where(make: "Chevrolet", model: "Silverado 1500"))
                              .or(Vehicle.where(make: "RAM", model: "1500"))
                              .or(Vehicle.where(make: "Toyota", model: %w[Tacoma 4Runner]))
  },
  {
    product_id: "gid://shopify/Product/10358754214046",
    product_handle: "apextow-7-pin-trailer-wiring-harness-full-size-trucks",
    product_title: "ApexTow 7-Pin Trailer Wiring Harness (Full-Size Trucks)",
    sku: "APX-TOW-WIRE-7",
    brand: "ApexTow",
    category: "Towing",
    price_cents: 4_900,
    short_description: "OEM-connectortail harness with LED-ready 7-blade plug.",
    universal: false,
    fitment_notes: "F-150, Silverado 1500 and RAM 1500 with factory tow package. Includes brake-controller pass-through.",
    position: "Rear Bumper",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150")
                              .or(Vehicle.where(make: "Chevrolet", model: "Silverado 1500"))
                              .or(Vehicle.where(make: "RAM", model: "1500"))
  },
  {
    product_id: "gid://shopify/Product/10358754214047",
    product_handle: "apexbeam-led-fog-light-kit-chevrolet-silverado",
    product_title: "ApexBeam LED Fog Light Kit (Chevrolet Silverado)",
    sku: "APX-FOG-KIT-SLV",
    brand: "ApexBeam",
    category: "Lighting",
    price_cents: 13_400,
    short_description: "5,000-lumen SAE-compliant LED pods with a wide flat beam that lights the shoulder line, not the fog bank.",
    universal: false,
    fitment_notes: "Bumper-opening fit for Silverado 1500 (2019+). Plug-and-play harness with dash switch.",
    position: "Front Bumper",
    matching_vehicles: Vehicle.where(make: "Chevrolet", model: "Silverado 1500")
  },

  # ---- Catalog wave 5: coverage balance (Towing, Electrical, Wipers, Lighting) ----
  {
    product_id: "gid://shopify/Product/10358754214048",
    product_handle: "apexshield-hard-folding-tonneau-cover-toyota-tacoma",
    product_title: "ApexShield Hard-Folding Tri-Fold Tonneau Cover (Toyota Tacoma)",
    sku: "APX-BED-CVR-TAC",
    brand: "ApexShield",
    category: "Exterior & Racks",
    price_cents: 69_900,
    short_description: "Fiberglass-reinforced hard panels with aluminum rails — locks tight, supports 400 lb on top, " \
                       "installs in 20 minutes.",
    universal: false,
    fitment_notes: "Fits Tacoma 5-ft and 6-ft beds (2016+). Clamp-on rails, no drilling.",
    position: "Truck Bed",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma")
  },
  {
    product_id: "gid://shopify/Product/10358754214049",
    product_handle: "apexbeam-led-tail-light-assembly-ford-mustang",
    product_title: "ApexBeam LED Tail Light Assembly, Set of 2 (Ford Mustang)",
    sku: "APX-LGT-TL-MST",
    brand: "ApexBeam",
    category: "Lighting",
    price_cents: 39_900,
    short_description: "Full-LED sequential assemblies with smoked lenses — instant-on braking and a turn sequence that announces you.",
    universal: false,
    fitment_notes: "Direct-fit for Mustang (2015+). Plug-and-play connectors, DOT/SAE compliant.",
    position: "Rear Body",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang")
  },
  {
    product_id: "gid://shopify/Product/10358754214050",
    product_handle: "apex-pro-slotted-rotors-chevrolet-silverado",
    product_title: "Apex Pro Slotted Front Rotors (Chevrolet Silverado 1500)",
    sku: "APX-BRK-ROT-SLV",
    brand: "Apex Performance",
    category: "Brakes",
    price_cents: 42_900,
    short_description: "Directionally slotted G3000 rotors for the Silverado — shed water and gas for fade-resistant towing stops.",
    universal: false,
    fitment_notes: "Fits Silverado 1500 (2019+) with 6-lug hubs. Sold as a pair; pads sold separately.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: "Chevrolet", model: "Silverado 1500")
  },
  {
    product_id: "gid://shopify/Product/10358754214051",
    product_handle: "apex-trailrunner-2-5-leveling-kit-f150",
    product_title: "Apex TrailRunner 2.5-Inch Front Leveling Kit (Ford F-150 4WD)",
    sku: "APX-SUSP-LFT-F150-25",
    brand: "Apex TrailRunner",
    category: "Suspension",
    price_cents: 15_900,
    short_description: "Billet strut spacers level the F-150's factory rake and clear 33-inch tires — keeps stock ride quality.",
    universal: false,
    fitment_notes: "Fits F-150 4WD (2015+). Front spacers only; alignment recommended.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "Ford", model: "F-150", drivetrain: "4WD")
  },
  {
    product_id: "gid://shopify/Product/10358754214052",
    product_handle: "apexpure-cabin-air-filter-ram-1500",
    product_title: "ApexPure Activated-Charcoal Cabin Air Filter (RAM 1500)",
    sku: "APX-CAB-AIR-RAM",
    brand: "ApexPure",
    category: "Filters",
    price_cents: 2_800,
    short_description: "Activated-charcoal layer blocks pollen, dust and highway diesel odors — a 10-minute glovebox swap.",
    universal: false,
    fitment_notes: "Fits RAM 1500 (2019+), all trims. Replaces OEM part, drop-in fit.",
    position: "Cabin",
    matching_vehicles: Vehicle.where(make: "RAM", model: "1500")
  },
  {
    product_id: "gid://shopify/Product/10358754214053",
    product_handle: "apexflow-high-flow-air-filter-honda-civic",
    product_title: "ApexFlow High-Flow Washable Air Filter (Honda Civic 1.5T)",
    sku: "APX-AIR-FIL-CIV",
    brand: "ApexFlow",
    category: "Filters",
    price_cents: 4_900,
    short_description: "Drop-in cotton-gauze filter for the stock airbox — +6 hp, washable for 100k miles of service.",
    universal: false,
    fitment_notes: "Fits Civic 1.5L Turbo (2016+) stock airbox, Sedan/Hatchback/Si.",
    position: "Engine Bay / Airbox",
    matching_vehicles: Vehicle.where(make: "Honda", model: "Civic")
  },
  {
    product_id: "gid://shopify/Product/10358754214054",
    product_handle: "apexflow-premium-oil-filter-bmw-3-series",
    product_title: "ApexFlow Premium Oil Filter (BMW 3 Series, B48/B58)",
    sku: "APX-OIL-FLT-BMW",
    brand: "ApexFlow",
    category: "Maintenance",
    price_cents: 1_900,
    short_description: "Synthetic-blend media with bypass valve tuned for turbocharged BMW engines — OEM-spec filtration.",
    universal: false,
    fitment_notes: "Fits 3 Series G20 330i (B48) and M340i (B58) (2019+). Includes o-ring.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  },
  {
    product_id: "gid://shopify/Product/10358754214055",
    product_handle: "apexfire-iridium-spark-plug-set-bmw-b48-b58",
    product_title: "ApexFire Iridium Spark Plug Set, 4-Piece (BMW B48/B58)",
    sku: "APX-SPK-IR-BMW",
    brand: "ApexFire",
    category: "Maintenance",
    price_cents: 5_600,
    short_description: "OEM-gap iridium plugs for the B48 and B58 turbo engines — smoother idle, sharper tip-in response.",
    universal: false,
    fitment_notes: "4-pc set for 3 Series G20 330i (B48) and M340i (B58) (2019+). Pre-gapped.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  },
  {
    product_id: "gid://shopify/Product/10358754214056",
    product_handle: "apexclear-beam-wiper-pair-subaru-outback",
    product_title: "ApexClear Beam Wiper Pair, 26\"/17\" (Subaru Outback)",
    sku: "APX-WIP-BLD-OUT",
    brand: "ApexClear",
    category: "Wipers & Visibility",
    price_cents: 3_200,
    short_description: "Exact-length beam blades for the Outback's curved glass — silent, streak-free sweeps down to -40°.",
    universal: false,
    fitment_notes: "Fits Outback (2020+): driver 26\", passenger 17\". Multi-adapter arms.",
    position: "Front Windshield",
    matching_vehicles: Vehicle.where(make: "Subaru", model: "Outback")
  },
  {
    product_id: "gid://shopify/Product/10358754214057",
    product_handle: "apex-powercell-agm-battery-bronco",
    product_title: "Apex PowerCell AGM Battery, Group 94R (Ford Bronco)",
    sku: "APX-BAT-AGM-BRN",
    brand: "Apex PowerCell",
    category: "Electrical",
    price_cents: 22_900,
    short_description: "AGM with 850 cold-crank amps and start-stop readiness — shrugs off trail vibration, 4-year warranty.",
    universal: false,
    fitment_notes: "Group 94R, fits Bronco 2.3L/2.7L (2021+). Vent tube included.",
    position: "Engine Bay / Battery Tray",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Bronco")
  },
  {
    product_id: "gid://shopify/Product/10358754214058",
    product_handle: "apexvolt-240a-high-output-alternator-silverado",
    product_title: "ApexVolt 240A High-Output Alternator (Chevrolet Silverado 1500)",
    sku: "APX-ALT-240A-SLV",
    brand: "ApexVolt",
    category: "Electrical",
    price_cents: 38_900,
    short_description: "240-amp output feeds work-site accessories and plow pumps without voltage sag at idle.",
    universal: false,
    fitment_notes: "Direct-fit for Silverado 1500 5.3L/6.2L V8 (2019+). Includes pulley.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Chevrolet", model: "Silverado 1500")
  },
  {
    product_id: "gid://shopify/Product/10358754214059",
    product_handle: "apexvolt-gear-reduction-starter-jeep-wrangler-3-6l",
    product_title: "ApexVolt Gear-Reduction Starter (Jeep Wrangler 3.6L)",
    sku: "APX-STA-GR-JL",
    brand: "ApexVolt",
    category: "Electrical",
    price_cents: 17_900,
    short_description: "Gear-reduction design spins faster while drawing less current — confident starts in cold weather.",
    universal: false,
    fitment_notes: "Direct-fit for Wrangler JL/JLU 3.6L Pentastar V6 (2018+). New, not remanufactured.",
    position: "Engine Bay",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
  },
  {
    product_id: "gid://shopify/Product/10358754214060",
    product_handle: "apexflow-throttle-body-cleaner-1-gal",
    product_title: "ApexFlow Throttle-Body & MAF Cleaner, 1 Gallon",
    sku: "APX-THRB-CLN-1GL",
    brand: "ApexFlow",
    category: "Maintenance",
    price_cents: 2_100,
    short_description: "Sensor-safe solvent strips carbon from throttle plates and MAF wires — restores idle quality in 20 minutes.",
    universal: true,
    fitment_notes: "Universal — safe for all gasoline engines, port and direct injection.",
    position: "Engine Bay"
  },
  {
    product_id: "gid://shopify/Product/10358754214061",
    product_handle: "apexcool-ready-mix-coolant-chevrolet-silverado",
    product_title: "ApexCool Ready-Mix 50/50 Coolant, 1 Gallon (Chevrolet Silverado)",
    sku: "APX-CLT-RMX-SLV",
    brand: "ApexCool",
    category: "Maintenance",
    price_cents: 2_100,
    short_description: "Dex-Cool-compatible OAT coolant, pre-mixed — top up or flush-fill the Silverado's cooling system.",
    universal: false,
    fitment_notes: "Recommended for Silverado 1500 (2019+) V8 engines. Pre-mixed, no distilled water needed.",
    position: "Cooling System",
    matching_vehicles: Vehicle.where(make: "Chevrolet", model: "Silverado 1500")
  },
  {
    product_id: "gid://shopify/Product/10358754214062",
    product_handle: "apexcomfort-neoprene-seat-covers-toyota-4runner",
    product_title: "ApexComfort Neoprene Seat Covers, Front Row (Toyota 4Runner)",
    sku: "APX-SEAT-CVR-4RN",
    brand: "ApexComfort",
    category: "Interior & Comfort",
    price_cents: 19_900,
    short_description: "4mm padded neoprene shrugs off wet gear and trail dust — custom-tailored, side-airbag safe.",
    universal: false,
    fitment_notes: "Front row, 4Runner (2010+). Airbag-compatible stitching, easy slip-on install.",
    position: "Cabin",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214063",
    product_handle: "apexshield-mud-flap-set-toyota-tacoma",
    product_title: "ApexShield Mud Flap Set, Front & Rear (Toyota Tacoma)",
    sku: "APX-MUD-FLP-TAC",
    brand: "ApexShield",
    category: "Exterior & Racks",
    price_cents: 6_900,
    short_description: "Weighted rubber flaps with stainless brackets keep gravel and slush off the paint and rockers.",
    universal: false,
    fitment_notes: "4-piece set, Tacoma (2016+). No-drill, bolts to factory points.",
    position: "Exterior",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "Tacoma")
  },
  {
    product_id: "gid://shopify/Product/10358754214064",
    product_handle: "apextow-4-pin-trailer-wiring-jeep-wrangler",
    product_title: "ApexTow 4-Pin Trailer Wiring Harness (Jeep Wrangler)",
    sku: "APX-TOW-WIRE-JL",
    brand: "ApexTow",
    category: "Towing",
    price_cents: 3_900,
    short_description: "Plug-and-play T-connector with 4-pin flat output — trailer lights on the trail or at the dump.",
    universal: false,
    fitment_notes: "Fits Wrangler JL/JLU (2018+) with factory tow package. No splicing.",
    position: "Rear Bumper",
    matching_vehicles: Vehicle.where(make: "Jeep", model: "Wrangler")
  },
  {
    product_id: "gid://shopify/Product/10358754214065",
    product_handle: "apexdrive-cv-axle-assembly-toyota-4runner",
    product_title: "ApexDrive Heavy-Duty CV Axle Assembly, Front (Toyota 4Runner)",
    sku: "APX-CV-AXLE-4RN",
    brand: "ApexDrive",
    category: "Chassis & Handling",
    price_cents: 14_500,
    short_description: "Over-center plunge CV joints hold up to lifted angles and 285s — trail-tested against OEM boots.",
    universal: false,
    fitment_notes: "Front axle, 4Runner (2010+). Rated for lifts up to 3 inches.",
    position: "Front Drivetrain",
    matching_vehicles: Vehicle.where(make: "Toyota", model: "4Runner")
  },
  {
    product_id: "gid://shopify/Product/10358754214066",
    product_handle: "apexgrip-front-sway-bar-ford-mustang",
    product_title: "ApexGrip Front Sway Bar, 34mm (Ford Mustang GT)",
    sku: "APX-SWAY-BAR-MST",
    brand: "ApexGrip",
    category: "Chassis & Handling",
    price_cents: 26_900,
    short_description: "34mm hollow bar with two stiffness settings — flattens cornering roll without beating up the ride.",
    universal: false,
    fitment_notes: "Fits Mustang GT/Mach 1 (2015+). Poly bushings and end links included.",
    position: "Front Suspension",
    matching_vehicles: Vehicle.where(make: "Ford", model: "Mustang")
  },
  {
    product_id: "gid://shopify/Product/10358754214067",
    product_handle: "apexstop-brake-caliper-rebuild-kit-bmw-3-series",
    product_title: "ApexStop Front Brake Caliper Rebuild Kit (BMW 3 Series)",
    sku: "APX-CAL-RBLD-BMW",
    brand: "ApexStop",
    category: "Brakes",
    price_cents: 4_200,
    short_description: "Seals, dust boots and bleed screws bring BMW calipers back to like-new clamping pressure.",
    universal: false,
    fitment_notes: "Front calipers, 3 Series G20 (2019+), all engines. EPDM seals, high-temp grease included.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  }
]

# Upserts one product's fitment records (universal or per-vehicle) and
# returns the number of rows created so the summary stays accurate.
def seed_fitment(shop, prod)
  detail_attrs = {
    product_handle: prod[:product_handle],
    product_title: prod[:product_title],
    sku: prod[:sku],
    brand: prod[:brand],
    category: prod[:category],
    price_cents: prod[:price_cents],
    short_description: prod[:short_description],
    fitment_notes: prod[:fitment_notes],
    position: prod[:position]
  }

  if prod[:universal]
    seed_fitment_row(shop:, prod:, detail_attrs:)
  else
    prod[:matching_vehicles].sum do |vehicle|
      seed_fitment_row(shop:, prod:, detail_attrs:, vehicle:)
    end
  end
end

def seed_fitment_row(shop:, prod:, detail_attrs:, vehicle: nil)
  fitment = VehicleProductFitment.find_or_create_by!(
    shop: shop,
    product_id: prod[:product_id],
    **{ vehicle: vehicle, universal_fit: vehicle.nil? }.compact
  ) do |f|
    f.assign_attributes(detail_attrs)
    f.universal_fit = vehicle.nil?
    f.synced_to_metafield = true
    f.last_synced_at = Time.current
  end
  fitment.update!(detail_attrs) unless detail_attrs.all? { |k, v| fitment.public_send(k) == v }
  1
end

# Prune fitments for products that are no longer part of the demo catalog
# (e.g. rows left over from an older seed). Keeps the demo shop's catalog
# exactly aligned with catalog_products so the storefront never renders
# half-populated cards.
catalog_ids = catalog_products.pluck(:product_id)
pruned = shop.vehicle_product_fitments.where.not(product_id: catalog_ids).delete_all
puts "✓ Pruned #{pruned} stale fitment rows no longer in the demo catalog" if pruned.positive?

fitment_count = 0
catalog_products.each do |prod|
  fitment_count += seed_fitment(shop, prod)
end

puts "✓ Successfully mapped #{fitment_count} vehicle-to-product fitment records!"
puts "== Database seeding complete! =="
