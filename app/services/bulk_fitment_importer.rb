require "csv"

class BulkFitmentImporter
  REQUIRED_HEADERS = %w[product_id year make model].freeze

  attr_reader :shop, :file_content, :results

  def initialize(shop, file_content)
    @shop = if defined?(Shop) && shop.is_a?(String)
              Shop.find_by!(shopify_domain: shop.to_s)
            else
              shop
            end
    @file_content = file_content
    @results = { success_count: 0, error_count: 0, errors: [], product_ids: Set.new }
  end

  def import!
    csv = CSV.parse(file_content, headers: true, header_converters: ->(h) { h.to_s.strip.downcase })

    # Validate minimal headers
    headers = csv.headers.compact
    unless headers.intersect?(%w[product_id product_handle sku])
      @results[:errors] << "CSV must contain at least one of: 'product_id', 'product_handle', or 'sku'"
      return @results
    end

    csv.each_with_index do |row, index|
      line_num = index + 2
      process_row(row, line_num)
    end

    # Enqueue metafield sync for affected products
    if @results[:product_ids].any? && defined?(Metafields::BatchSyncJob)
      Metafields::BatchSyncJob.perform_later(@shop.id, @results[:product_ids].to_a)
    end

    @results
  rescue CSV::MalformedCSVError => e
    @results[:errors] << "Malformed CSV: #{e.message}"
    @results
  rescue StandardError => e
    @results[:errors] << "Unexpected error: #{e.message}"
    @results
  end

  private

  # rubocop:disable-next Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity -- legacy row parser; covered by bulk_fitment_importer_spec, refactor deferred
  def process_row(row, line_num)
    product_id = row["product_id"].presence || row["product_handle"].presence || row["sku"].presence
    if product_id.blank?
      @results[:errors] << "Row #{line_num}: Missing product identifier"
      @results[:error_count] += 1
      return
    end

    is_universal = %w[true 1 yes y universal].include?(row["universal"].to_s.downcase)

    if is_universal
      fitment = @shop.vehicle_product_fitments.find_or_initialize_by(
        product_id: product_id,
        universal_fit: true
      )
      fitment.product_handle = row["product_handle"] if row["product_handle"].present?
      fitment.product_title = row["product_title"] if row["product_title"].present?
      fitment.sku = row["sku"] if row["sku"].present?
      fitment.product_image = row["image"].presence || row["image_url"].presence
      fitment.fitment_notes = row["notes"] || row["fitment_notes"]
      fitment.position = row["position"]
      fitment.save!

      @results[:success_count] += 1
      @results[:product_ids] << product_id
      return
    end

    year = row["year"].to_i
    make = row["make"].to_s.strip
    model = row["model"].to_s.strip
    trim = row["trim"].to_s.strip.presence
    engine = row["engine"].to_s.strip.presence

    if year <= 0 || make.blank? || model.blank?
      @results[:errors] << "Row #{line_num}: Non-universal fitment requires Year, Make, and Model"
      @results[:error_count] += 1
      return
    end

    # Find or create vehicle if model exists
    vehicle = nil
    if defined?(Vehicle)
      vehicle = find_or_create_vehicle(
        year: year, make: make, model: model, trim: trim, engine: engine,
        row: row
      )
    end

    # Create fitment
    fitment = @shop.vehicle_product_fitments.find_or_initialize_by(
      product_id: product_id,
      vehicle: vehicle
    )
    fitment.product_handle = row["product_handle"] if row["product_handle"].present?
    fitment.product_title = row["product_title"] if row["product_title"].present?
    fitment.sku = row["sku"] if row["sku"].present?
    fitment.product_image = row["image"].presence || row["image_url"].presence
    fitment.universal_fit = false
    fitment.fitment_type = row["fitment_type"].presence || "direct_fit"
    fitment.fitment_notes = row["notes"] || row["fitment_notes"]
    fitment.position = row["position"]
    fitment.save!

    @results[:success_count] += 1
    @results[:product_ids] << product_id
  rescue StandardError => e
    @results[:errors] << "Row #{line_num}: #{e.message}"
    @results[:error_count] += 1
  end

  # find_or_create_by! can lose a concurrent-insert race on the unique YMMTE
  # index (validation passes, INSERT raises RecordInvalid). When that happens
  # the vehicle exists — look it up again instead of failing the row.
  def find_or_create_vehicle(year:, make:, model:, trim:, engine:, row:)
    Vehicle.find_or_create_by!(year: year, make: make, model: model, trim: trim, engine: engine) do |v|
      v.drivetrain = row["drivetrain"].to_s.strip.presence
      v.body_style = row["body_style"].to_s.strip.presence
      v.active = true
    end
  rescue ActiveRecord::RecordInvalid
    Vehicle.find_by!(year: year, make: make, model: model, trim: trim, engine: engine)
  end
end
