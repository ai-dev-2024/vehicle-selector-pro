# Demo-only product spec sheets for the seeded catalog. Pure static data
# (mirrors real manufacturer spec sheets); size is inherent to the content,
# so Metrics/ModuleLength is waived.
# rubocop:disable-next Metrics/ModuleLength -- pure static catalog data
module DemoProductSpecs
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
    },
    "APX-CAI-RAM-V8" => {
      features: [
        "Rotomolded high-flow tube with smooth interior walls",
        "Washable conical filter, service every 50k miles",
        "Heat shield isolates intake air from engine bay soak",
        "Dyno-verified +15 hp on the 5.7L HEMI — no tune required"
      ],
      specs: [
        ["Gains", "+15 hp / +19 lb-ft @ wheels"],
        ["Design", "Rotomolded tube + heat shield"],
        ["Filter", "Washable conical"],
        ["Fitment", "RAM 1500 5.7L HEMI 2019+ (incl. eTorque)"],
        ["Warranty", "Lifetime limited (filter: 1 year)"]
      ]
    },
    "APX-EXH-RAM-V8" => {
      features: [
        "Full 2.75-inch mandrel-bent T-304 stainless tubing",
        "Straight-through mufflers: deep under load, mild at cruise",
        "Keeps factory catalytic converters and rear oxygen sensors",
        "Bolts to OEM flanges — no cutting or welding"
      ],
      specs: [
        ["Material", "T-304 stainless, TIG-welded"],
        ["Tube diameter", "2.75 in mandrel-bent"],
        ["Tips", "Dual 4-inch polished stainless"],
        ["Fitment", "RAM 1500 5.7L HEMI 2019+"],
        ["Warranty", "Lifetime on materials and workmanship"]
      ]
    },
    "APX-SUSP-LFT-RAM-25" => {
      features: [
        "Billet 6061-T6 front strut spacers — true 2.5-inch level",
        "Corrects the RAM's factory rake for a level stance",
        "Clears up to 35-inch tires after alignment",
        "Keeps factory coils and shocks — no ride-quality penalty"
      ],
      specs: [
        ["Lift", "2.5 in front level"],
        ["Material", "Billet 6061-T6, anodized"],
        ["Tire clearance", "Up to 35 in (alignment required)"],
        ["Fitment", "RAM 1500 4WD 2019+"],
        ["Warranty", "Limited lifetime"]
      ]
    },
    "APX-CAI-CIV-15T" => {
      features: [
        "Rotomolded short-ram with integral heat shield",
        "Dry synthetic media — no oiling, no MAF contamination",
        "Dyno-verified +9 hp / +11 lb-ft on the 1.5L turbo",
        "Installs with hand tools in about an hour"
      ],
      specs: [
        ["Gains", "+9 hp / +11 lb-ft @ wheels"],
        ["Filter", "Dry synthetic, washable"],
        ["Design", "Short-ram + heat shield"],
        ["Fitment", "Civic 1.5L Turbo 2016+ (Sedan/Hatch/Si)"],
        ["Warranty", "Lifetime limited (filter: 1 year)"]
      ]
    },
    "APX-CHP-SPR-CIV" => {
      features: [
        "Progressive-rate steel springs: -1.2 in front, -1.0 in rear",
        "Soft initial rate keeps daily-comfort ride quality",
        "Stiffer final rate sharpens turn-in and cuts body roll",
        "Shot-peened and powder-coated for corrosion resistance"
      ],
      specs: [
        ["Drop", "-1.2 in front / -1.0 in rear"],
        ["Rate", "Progressive linear"],
        ["Material", "Shot-peened chrome-silicon steel"],
        ["Fitment", "Civic 1.5T 2016+ incl. Si"],
        ["Warranty", "Limited lifetime against sagging"]
      ]
    },
    "APX-EXT-RACK-OUT" => {
      features: [
        "Wing-profile aluminum bars cut wind whistle at highway speed",
        "165 lb dynamic load — boxes, bikes, kayaks and skis",
        "Mounts to Outback factory fixed points in under an hour",
        "T-nut channel accepts most accessory carriers"
      ],
      specs: [
        ["Load rating", "165 lb dynamic / 500 lb static"],
        ["Material", "Anodized 6063 aluminum"],
        ["Fitment", "Outback 2020+ factory points"],
        ["Install", "~45 minutes, hex key included"],
        ["Warranty", "Limited lifetime"]
      ]
    },
    "APX-BRK-PAD-OUT" => {
      features: [
        "Ceramic compound rated for a loaded wagon plus roof cargo",
        "Front and rear sets in one box — complete pad service",
        "Shimmed backing plates kill squeal and rattle",
        "Hardware clips included for both axles"
      ],
      specs: [
        ["Compound", "Ceramic, low-dust"],
        ["Coverage", "Front + rear axle sets"],
        ["Fitment", "Outback 2015+"],
        ["Includes", "Shims and hardware, both axles"],
        ["Warranty", "2 years / 24,000 miles"]
      ]
    },
    "APX-CAI-BRN-27" => {
      features: [
        "Sealed airbox with hydro-shield prefilter for wet trail runs",
        "Dyno-verified +14 hp on the 2.7L EcoBoost",
        "Heat shield seals against the hood for cool intake air",
        "Washable filter — service every 30k miles off-road"
      ],
      specs: [
        ["Gains", "+14 hp / +17 lb-ft @ wheels"],
        ["Design", "Sealed airbox + hydro-shield"],
        ["Fitment", "Bronco 2.7L EcoBoost 2021+"],
        ["Install", "~90 minutes, hand tools"],
        ["Warranty", "Lifetime limited (filter: 1 year)"]
      ]
    },
    "APX-LGT-POD-BRN" => {
      features: [
        "Six 3-inch 4,800 lm pods on a hidden-channel roof plate",
        "No-drill mount to Bronco factory roof rack rails",
        "Wiring runs inside the rack channels — clean install",
        "Individual pod aiming: spot up front, flood to the sides"
      ],
      specs: [
        ["Light output", "14,400 lm total (6 pods)"],
        ["Mount", "Factory roof rack rails, no drill"],
        ["Ingress", "IP68 pods"],
        ["Fitment", "Bronco 2021+ with factory rack"],
        ["Warranty", "3 years against defect and moisture"]
      ]
    },
    "APX-TOW-HITCH-SLV" => {
      features: [
        "SAE J684 Class IV — 12,000 lb GTW, 1,200 lb tongue",
        "2-inch receiver for ball mounts, racks and carriers",
        "Bolt-on to Silverado factory mount points — no drilling",
        "E-coat + powder coat resists winter road salt"
      ],
      specs: [
        ["Class", "IV (SAE J684)"],
        ["Receiver", "2 in square"],
        ["Rating", "12,000 lb GTW / 1,200 lb tongue"],
        ["Fitment", "Silverado 1500 2014+"],
        ["Warranty", "Lifetime structural"]
      ]
    },
    "APX-BRK-ROT-MST" => {
      features: [
        "Directionally slotted vanes evacuate gas, water and dust",
        "G3000 gray iron, mill-balanced under 20 g per side",
        "Black electro-coating on hat and edges prevents rust rings",
        "Track-validated with the Apex QuietStop pad compound"
      ],
      specs: [
        ["Finish", "Slotted, Geomet-coated"],
        ["Diameter", "OEM 352 mm (GT)"],
        ["Fitment", "Mustang 5.0L V8 2015+ (pair)"],
        ["Balance", "< 20 g residual"],
        ["Warranty", "2 years against warp and crack"]
      ]
    },
    "APX-SUSP-SHCK-TAC" => {
      features: [
        "Twin-tube gas shocks tuned for Tacoma 4WD load carriers",
        "Comfortable 0-inch through 3-inch lift range",
        "Expanded reserve delays fade on washboard descents",
        "Sold as a matched rear pair with all bushings"
      ],
      specs: [
        ["Type", "Twin-tube gas, rear pair"],
        ["Lift range", "0–3 in"],
        ["Fitment", "Tacoma 4WD 2016+"],
        ["Valving", "Load-tuned, velocity sensitive"],
        ["Warranty", "Limited lifetime (1 yr seal)"]
      ]
    }
  }.freeze
end
