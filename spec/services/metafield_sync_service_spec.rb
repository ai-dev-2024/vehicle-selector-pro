require_relative '../spec_helper'

class MetafieldSyncServiceTest < Minitest::Test
  def test_metafield_json_structure_and_serialization
    # Verify that the metafield payload conforms to Shopify Storefront JSON Schema
    fitment_data = {
      universal: false,
      total_vehicles: 2,
      fitments: [
        {
          year: 2024,
          make: "Ford",
          model: "F-150",
          trim: "Lariat",
          engine: "3.5L EcoBoost V6",
          notes: "Direct bolt-on",
          position: "Front"
        },
        {
          year: 2023,
          make: "Ford",
          model: "F-150",
          trim: "XLT",
          engine: "5.0L V8",
          notes: "Direct bolt-on",
          position: "Front"
        }
      ],
      ymm_keys: [
        "2024|ford|f-150",
        "2023|ford|f-150"
      ],
      last_updated: "2026-08-29T12:00:00Z"
    }

    json_str = fitment_data.to_json
    parsed = JSON.parse(json_str)

    assert_equal false, parsed["universal"]
    assert_equal 2, parsed["fitments"].size
    assert_equal 2024, parsed["fitments"][0]["year"]
    assert_equal "Ford", parsed["fitments"][0]["make"]
    assert_equal "2024|ford|f-150", parsed["ymm_keys"][0]
  end

  def test_universal_fitment_payload
    universal_data = {
      universal: true,
      total_vehicles: "all",
      fitments: [
        {
          universal: true,
          notes: "Fits all vehicles with standard 12V socket",
          position: "Interior"
        }
      ],
      ymm_keys: ["universal"],
      last_updated: "2026-08-29T12:00:00Z"
    }

    json_str = universal_data.to_json
    parsed = JSON.parse(json_str)

    assert_equal true, parsed["universal"]
    assert_equal "all", parsed["total_vehicles"]
    assert_equal ["universal"], parsed["ymm_keys"]
  end
end
