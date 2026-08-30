require "rails_helper"

RSpec.describe VehicleHierarchyService do
  before do
    Rails.cache.clear
    # The dev/test database carries the seeded demo catalog; scope the tree
    # test to its own vehicles so shared data can't leak into assertions.
    Vehicle.delete_all
  end

  it "builds a deduplicated year → make → model tree" do
    # 2088/2089 are beyond every other spec's data — the tree is global, so
    # this spec must not collide with fixtures created elsewhere.
    create(:vehicle, year: 2089, make: "Ford", model: "F-150", trim: "Lariat", engine: "3.5L")
    create(:vehicle, year: 2089, make: "Ford", model: "F-150", trim: "XLT", engine: "2.7L")
    create(:vehicle, year: 2088, make: "Toyota", model: "Tacoma", trim: "TRD", engine: "3.5L")

    tree = described_class.full_tree

    expect(tree.keys).to include(2089, 2088)
    expect(tree[2089].keys).to contain_exactly("Ford")
    expect(tree[2089]["Ford"].keys).to contain_exactly("F-150")
    expect(tree[2089]["Ford"]["F-150"][:trims]).to contain_exactly("Lariat", "XLT")
    expect(tree[2089]["Ford"]["F-150"][:engines]).to contain_exactly("3.5L", "2.7L")
  end
end
