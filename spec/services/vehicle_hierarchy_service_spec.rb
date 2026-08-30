require_relative "../spec_helper"

class VehicleHierarchyServiceTest < Minitest::Test
  def test_hierarchy_tree_structure_deduplication
    raw_vehicles = [
      { year: 2024, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L EcoBoost V6" },
      { year: 2024, make: "Ford", model: "F-150", trim: "XLT", engine: "2.7L EcoBoost V6" },
      { year: 2024, make: "Ford", model: "Mustang", trim: "GT", engine: "5.0L V8" },
      { year: 2023, make: "Toyota", model: "Tacoma", trim: "TRD Off-Road", engine: "3.5L V6" }
    ]

    tree = {}
    raw_vehicles.each do |v|
      tree[v[:year]] ||= {}
      tree[v[:year]][v[:make]] ||= {}
      tree[v[:year]][v[:make]][v[:model]] ||= { trims: [], engines: [] }

      tree[v[:year]][v[:make]][v[:model]][:trims] << v[:trim]
      tree[v[:year]][v[:make]][v[:model]][:engines] << v[:engine]
    end

    assert_includes tree.keys, 2024
    assert_includes tree.keys, 2023
    assert_includes tree[2024].keys, "Ford"
    assert_includes tree[2024]["Ford"].keys, "F-150"
    assert_includes tree[2024]["Ford"].keys, "Mustang"
    assert_equal %w[Lariat XLT], tree[2024]["Ford"]["F-150"][:trims]
    assert_equal ["3.5L EcoBoost V6", "2.7L EcoBoost V6"], tree[2024]["Ford"]["F-150"][:engines]
  end
end
