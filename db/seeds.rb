# Seed file for Vehicle Selector Pro
puts "== Seeding Vehicle Selector Pro Database =="

# 1. Create Demo Shop (uses the configured store domain; falls back to the
#    bundled demo store so local development works out of the box)
demo_domain = ENV.fetch('SHOPIFY_STORE_DOMAIN', 'vehicle-selector-pro.myshopify.com')
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
  { year: 2024, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "XLT", engine: "2.7L EcoBoost V6", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "Raptor", engine: "3.5L High-Output EcoBoost V6", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2024, make: "Ford", model: "F-150", trim: "Platinum", engine: "5.0L Ti-VCT V8", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2023, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2023, make: "Ford", model: "F-150", trim: "XLT", engine: "5.0L Ti-VCT V8", drivetrain: "RWD", body_style: "SuperCab" },
  { year: 2022, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6", drivetrain: "4WD", body_style: "SuperCrew" },
  { year: 2021, make: "Ford", model: "F-150", trim: "XLT", engine: "3.5L PowerBoost Full Hybrid V6", drivetrain: "4WD", body_style: "SuperCrew" },

  # Ford Mustang (2020-2024)
  { year: 2024, make: "Ford", model: "Mustang", trim: "GT Premium", engine: "5.0L Coyote V8", drivetrain: "RWD", body_style: "Fastback Coupe" },
  { year: 2024, make: "Ford", model: "Mustang", trim: "Dark Horse", engine: "5.0L Modified Coyote V8", drivetrain: "RWD", body_style: "Fastback Coupe" },
  { year: 2023, make: "Ford", model: "Mustang", trim: "EcoBoost", engine: "2.3L Turbocharged I4", drivetrain: "RWD", body_style: "Fastback Coupe" },
  { year: 2022, make: "Ford", model: "Mustang", trim: "Mach 1", engine: "5.0L Coyote V8", drivetrain: "RWD", body_style: "Fastback Coupe" },

  # Chevrolet Silverado 1500 (2021-2024)
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "LTZ", engine: "6.2L EcoTec3 V8", drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "RST", engine: "5.3L EcoTec3 V8", drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2024, make: "Chevrolet", model: "Silverado 1500", trim: "ZR2", engine: "3.0L Duramax Turbo-Diesel I6", drivetrain: "4WD", body_style: "Crew Cab" },
  { year: 2023, make: "Chevrolet", model: "Silverado 1500", trim: "LT", engine: "2.7L TurboMax I4", drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2022, make: "Chevrolet", model: "Silverado 1500", trim: "Custom", engine: "5.3L EcoTec3 V8", drivetrain: "RWD", body_style: "Crew Cab" },

  # Toyota Tacoma (2020-2024)
  { year: 2024, make: "Toyota", model: "Tacoma", trim: "TRD Off-Road", engine: "2.4L i-FORCE Turbo I4", drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2024, make: "Toyota", model: "Tacoma", trim: "TRD Pro", engine: "2.4L i-FORCE MAX Hybrid Turbo I4", drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2023, make: "Toyota", model: "Tacoma", trim: "TRD Sport", engine: "3.5L V6 DOHC", drivetrain: "4WD", body_style: "Access Cab" },
  { year: 2022, make: "Toyota", model: "Tacoma", trim: "SR5", engine: "3.5L V6 DOHC", drivetrain: "4WD", body_style: "Double Cab" },
  { year: 2021, make: "Toyota", model: "Tacoma", trim: "TRD Off-Road", engine: "3.5L V6 DOHC", drivetrain: "4WD", body_style: "Double Cab" },

  # Toyota 4Runner (2020-2024)
  { year: 2024, make: "Toyota", model: "4Runner", trim: "TRD Pro", engine: "4.0L 1GR-FE V6", drivetrain: "4WD", body_style: "SUV" },
  { year: 2023, make: "Toyota", model: "4Runner", trim: "TRD Off-Road Premium", engine: "4.0L 1GR-FE V6", drivetrain: "4WD", body_style: "SUV" },
  { year: 2022, make: "Toyota", model: "4Runner", trim: "Limited", engine: "4.0L 1GR-FE V6", drivetrain: "AWD", body_style: "SUV" },

  # Jeep Wrangler (2021-2024)
  { year: 2024, make: "Jeep", model: "Wrangler", trim: "Rubicon 392", engine: "6.4L HEMI V8", drivetrain: "4WD", body_style: "4-Door SUV" },
  { year: 2024, make: "Jeep", model: "Wrangler", trim: "Rubicon 4xe", engine: "2.0L Turbo PHEV I4", drivetrain: "4WD", body_style: "4-Door SUV" },
  { year: 2023, make: "Jeep", model: "Wrangler", trim: "Sahara", engine: "3.6L Pentastar V6 with eTorque", drivetrain: "4WD", body_style: "4-Door SUV" },
  { year: 2022, make: "Jeep", model: "Wrangler", trim: "Sport S", engine: "2.0L Turbocharged I4", drivetrain: "4WD", body_style: "2-Door SUV" },

  # BMW 3 Series (2021-2024)
  { year: 2024, make: "BMW", model: "3 Series", trim: "M340i xDrive", engine: "3.0L TwinPower Turbo B58 I6", drivetrain: "AWD", body_style: "Sedan" },
  { year: 2024, make: "BMW", model: "3 Series", trim: "330i", engine: "2.0L TwinPower Turbo B48 I4", drivetrain: "RWD", body_style: "Sedan" },
  { year: 2023, make: "BMW", model: "3 Series", trim: "M3 Competition", engine: "3.0L M TwinPower Turbo S58 I6", drivetrain: "AWD", body_style: "Sedan" },
  { year: 2022, make: "BMW", model: "3 Series", trim: "330e", engine: "2.0L TwinPower Turbo PHEV I4", drivetrain: "RWD", body_style: "Sedan" }
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
    price_cents: 34900,
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
    price_cents: 48900,
    short_description: "Severe-duty drilled & slotted rotors with carbon-ceramic pads — shorter stops, less fade under towing loads.",
    universal: false,
    fitment_notes: "Front axle only. Fits 6-lug wheel hubs.",
    position: "Front Axle",
    matching_vehicles: Vehicle.where(make: ["Ford", "Chevrolet"], model: ["F-150", "Silverado 1500"])
  },
  {
    product_id: "gid://shopify/Product/10358754050324",
    product_handle: "apex-baja-3-inch-suspension-lift-kit-tacoma",
    product_title: "Apex Baja 3-Inch Coilovers & Billet Control Arm Lift System",
    sku: "APX-SUSP-TACO-3IN",
    brand: "Apex Performance",
    category: "Suspension",
    price_cents: 114900,
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
    price_cents: 89900,
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
    price_cents: 74900,
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
    price_cents: 18900,
    short_description: "3-inch SAE/DOT street-legal amber LED pods, 4,800 lm per pair, IP68 sealed — mounts anywhere with included brackets.",
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
    price_cents: 32900,
    short_description: "Dry-carbon strut tower brace — sharpens turn-in and cuts front-end flex without adding weight.",
    universal: false,
    fitment_notes: "Fits G20 3-Series chassis (330i, M340i, M3). Enhances front-end torsional rigidity.",
    position: "Front Strut Towers",
    matching_vehicles: Vehicle.where(make: "BMW", model: "3 Series")
  }
]

fitment_count = 0
catalog_products.each do |prod|
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
    # Create universal fitment
    VehicleProductFitment.find_or_create_by!(
      shop: shop,
      product_id: prod[:product_id],
      universal_fit: true
    ) do |f|
      f.assign_attributes(detail_attrs)
      f.synced_to_metafield = true
      f.last_synced_at = Time.current
    end.tap { |f| f.update!(detail_attrs) unless f.saved_changes.empty? && detail_attrs.all? { |k, v| f.public_send(k) == v } }
    fitment_count += 1
  else
    prod[:matching_vehicles].each do |veh|
      VehicleProductFitment.find_or_create_by!(
        shop: shop,
        vehicle: veh,
        product_id: prod[:product_id]
      ) do |f|
        f.assign_attributes(detail_attrs)
        f.universal_fit = false
        f.synced_to_metafield = true
        f.last_synced_at = Time.current
      end.tap { |f| f.update!(detail_attrs) unless detail_attrs.all? { |k, v| f.public_send(k) == v } }
      fitment_count += 1
    end
  end
end

puts "✓ Successfully mapped #{fitment_count} vehicle-to-product fitment records!"
puts "== Database seeding complete! =="
