require_relative '../spec_helper'

class BulkFitmentImporterTest < Minitest::Test
  class MockFitmentsCollection
    attr_reader :records

    def initialize
      @records = []
    end

    def find_or_initialize_by(attrs)
      existing = @records.find do |r|
        attrs.all? { |k, v| r.respond_to?(k) && r.send(k) == v }
      end
      return existing if existing

      record = MockFitmentRecord.new(attrs)
      @records << record
      record
    end

    def where(attrs)
      @records.select do |r|
        attrs.all? { |k, v| r.respond_to?(k) && r.send(k) == v }
      end
    end
  end

  class MockFitmentRecord
    attr_accessor :product_id, :product_handle, :product_title, :sku,
                  :vehicle, :universal_fit, :fitment_type, :fitment_notes, :position, :shop_id

    def initialize(attrs = {})
      attrs.each { |k, v| send("#{k}=", v) if respond_to?("#{k}=") }
    end

    def save!
      true
    end
  end

  class MockShop
    attr_accessor :id, :shopify_domain, :fitments_collection

    def initialize
      @id = 1
      @shopify_domain = "apex-test.myshopify.com"
      @fitments_collection = MockFitmentsCollection.new
    end

    def vehicle_product_fitments
      @fitments_collection
    end

    def active?
      true
    end
  end

  def setup
    @shop = MockShop.new
  end

  def test_csv_parser_with_valid_rows
    csv_text = <<~CSV
      product_id,product_handle,product_title,year,make,model,trim,engine,universal,notes
      gid://shopify/Product/1001,cold-air-intake,Cold Air Intake,2024,Ford,F-150,Lariat,3.5L EcoBoost,false,Direct fit
      gid://shopify/Product/1002,universal-floor-mats,Rubber Floor Mats,,,,,,true,Universal fit
    CSV

    importer = BulkFitmentImporter.new(@shop, csv_text)
    result = importer.import!

    if result[:errors].any?
      puts "Importer errors: #{result[:errors].inspect}"
    end

    assert_equal 2, result[:success_count]
    assert_equal 0, result[:error_count]
  end

  def test_csv_missing_required_headers_returns_error
    csv_text = <<~CSV
      unrelated_column_a,unrelated_column_b
      value_1,value_2
    CSV

    importer = BulkFitmentImporter.new(@shop, csv_text)
    result = importer.import!

    assert_includes result[:errors].first, "CSV must contain at least one of"
    assert_equal 0, result[:success_count]
  end
end
