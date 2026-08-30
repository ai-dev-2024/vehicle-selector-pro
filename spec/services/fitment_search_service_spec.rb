require_relative "../spec_helper"

class FitmentSearchServiceTest < Minitest::Test
  class MockVehicle
    attr_accessor :id, :year, :make, :model, :trim, :engine, :drivetrain, :body_style

    def initialize(attrs)
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def display_name
      [year, make, model, trim, engine].compact.join(" ")
    end

    def to_h
      {
        id: id,
        year: year,
        make: make,
        model: model,
        trim: trim,
        engine: engine,
        display_name: display_name
      }
    end
  end

  class MockVehicleFitment
    attr_accessor :id, :shop_id, :product_id, :product_handle, :product_title, :sku, :vehicle, :universal_fit,
                  :fitment_type, :fitment_notes, :position

    def initialize(attrs)
      attrs.each { |k, v| send("#{k}=", v) }
    end

    def universal_fit?
      universal_fit == true
    end
  end

  def test_exact_fitment_evaluation
    vehicle = MockVehicle.new(
      id: 101,
      year: 2024,
      make: "Ford",
      model: "F-150",
      trim: "Lariat",
      engine: "3.5L EcoBoost V6"
    )

    fitment = MockVehicleFitment.new(
      id: 1,
      shop_id: 1,
      product_id: "gid://shopify/Product/1001",
      product_title: "Performance Cold Air Intake",
      vehicle: vehicle,
      universal_fit: false,
      fitment_type: "direct_fit",
      fitment_notes: "Direct bolt-on replacement for 3.5L EcoBoost"
    )

    assert_equal false, fitment.universal_fit?
    assert_equal "direct_fit", fitment.fitment_type
    assert_equal "2024 Ford F-150 Lariat 3.5L EcoBoost V6", fitment.vehicle.display_name
  end

  def test_universal_fitment_evaluation
    universal_fitment = MockVehicleFitment.new(
      id: 2,
      shop_id: 1,
      product_id: "gid://shopify/Product/2001",
      product_title: "Heavy Duty Floor Mats",
      vehicle: nil,
      universal_fit: true,
      fitment_type: "universal",
      fitment_notes: "Universal trim-to-fit channels"
    )

    assert_equal true, universal_fitment.universal_fit?
    assert_nil universal_fitment.vehicle
  end
end
