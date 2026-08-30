class FitmentSearchService
  CACHE_TTL = 1.hour

  def self.invalidate_shop_cache(shop_id)
    # Increment shop version token in cache to instantly invalidate all cached queries
    Rails.cache.write("vsp/shop_version/#{shop_id}", Time.current.to_i)
  end

  def self.shop_version(shop_id)
    Rails.cache.fetch("vsp/shop_version/#{shop_id}", expires_in: 24.hours) { 1 }
  end

  # Returns every stored representation of a product id so lookups match
  # whether the caller passes a numeric id or a GraphQL global id (GID).
  # Shopify themes expose product.id as a plain integer, while the API and
  # metafields use gid://shopify/Product/<id>, so both forms must resolve.
  def self.product_id_variants(product_id)
    pid = product_id.to_s.strip
    return [] if pid.blank?

    gid_prefix = "gid://shopify/Product/"
    if pid.start_with?(gid_prefix)
      [pid, pid.delete_prefix(gid_prefix)]
    else
      [pid, "#{gid_prefix}#{pid}"]
    end
  end

  def initialize(shop)
    @shop = shop.is_a?(Shop) ? shop : Shop.find_by!(shopify_domain: shop.to_s)
    @version = self.class.shop_version(@shop.id)
  end

  def years
    cache_fetch("years") do
      @shop.vehicles.distinct.order(year: :desc).pluck(:year)
    end
  end

  def makes(year:)
    return [] if year.blank?

    cache_fetch("makes/#{year}") do
      @shop.vehicles.where(year: year).distinct.order(:make).pluck(:make)
    end
  end

  def models(year:, make:)
    return [] if year.blank? || make.blank?

    cache_fetch("models/#{year}/#{make.downcase}") do
      @shop.vehicles.where(year: year).where("LOWER(make) = ?",
                                             make.downcase.strip).distinct.order(:model).pluck(:model)
    end
  end

  def trims(year:, make:, model:)
    return [] if year.blank? || make.blank? || model.blank?

    cache_fetch("trims/#{year}/#{make.downcase}/#{model.downcase}") do
      @shop.vehicles
           .where(year: year)
           .where("LOWER(make) = ?", make.downcase.strip)
           .where("LOWER(model) = ?", model.downcase.strip)
           .where.not(trim: [nil, ""])
           .distinct.order(:trim).pluck(:trim)
    end
  end

  def engines(year:, make:, model:, trim: nil)
    return [] if year.blank? || make.blank? || model.blank?

    cache_key = "engines/#{year}/#{make.downcase}/#{model.downcase}/#{trim.to_s.downcase}"
    cache_fetch(cache_key) do
      query = @shop.vehicles
                   .where(year: year)
                   .where("LOWER(make) = ?", make.downcase.strip)
                   .where("LOWER(model) = ?", model.downcase.strip)
      query = query.where("LOWER(trim) = ?", trim.downcase.strip) if trim.present?
      query.where.not(engine: [nil, ""]).distinct.order(:engine).pluck(:engine)
    end
  end

  # Search results are paginated with a hard cap so a page request never loads
  # the whole catalog into memory. Only matching product IDs are plucked from
  # the database (cheap), the unique ID list is paginated in Ruby, and full
  # fitment rows are fetched only for the products on the requested page.
  MAX_PAGE_SIZE = 100

  def search_products(year:, make:, model:, trim: nil, engine: nil, limit: 50, page: 1)
    limit = limit.to_i.clamp(1, MAX_PAGE_SIZE)
    page = [page.to_i, 1].max
    offset = (page - 1) * limit

    vehicle_ids = matching_vehicle_ids(year: year, make: make, model: model, trim: trim, engine: engine)
    product_ids = matching_product_ids(vehicle_ids)

    products = build_products(product_ids.drop(offset).first(limit))
    numeric_ids = product_ids.map { |pid| pid.to_s.gsub("gid://shopify/Product/", "") }

    # Metafield filter tokens for storefront Liquid integration
    filter_tag = "#{year}|#{make.to_s.downcase}|#{model.to_s.downcase}"

    {
      vehicle: {
        year: year,
        make: make,
        model: model,
        trim: trim,
        engine: engine,
        display_name: [year, make, model, trim, engine].compact_blank.join(" ")
      },
      total_count: product_ids.size,
      product_ids: product_ids,
      numeric_product_ids: numeric_ids,
      filter_token: filter_tag,
      products: products
    }
  end

  def check_fitment(product_id:, vehicle_id: nil, year: nil, make: nil, model: nil, trim: nil, engine: nil)
    pid_variants = self.class.product_id_variants(product_id)

    # Check if universal fit first
    universal = @shop.vehicle_product_fitments.universal.find_by(product_id: pid_variants)
    return universal_fit_response(universal, product_id) if universal.present?

    target_vehicle = resolve_target_vehicle(vehicle_id: vehicle_id, year: year, make: make,
                                            model: model, trim: trim, engine: engine)
    return vehicle_not_specified_response if target_vehicle.nil?

    fitment = @shop.vehicle_product_fitments.find_by(product_id: pid_variants, vehicle_id: target_vehicle.id)
    if fitment.present?
      exact_fit_response(fitment, target_vehicle, product_id)
    else
      no_fit_response(target_vehicle, product_id)
    end
  end

  private

  def resolve_target_vehicle(vehicle_id: nil, year: nil, make: nil, model: nil, trim: nil, engine: nil)
    return Vehicle.find_by(id: vehicle_id) if vehicle_id.present?
    return nil unless year.present? && make.present? && model.present?

    query = Vehicle.by_year(year).by_make(make).by_model(model)
    query = query.by_trim(trim) if trim.present?
    query = query.by_engine(engine) if engine.present?
    query.first
  end

  def universal_fit_response(universal, product_id)
    {
      fits: true,
      fitment_type: "universal",
      badge_text: "Universal Fit",
      badge_color: "success",
      notes: universal.fitment_notes.presence || "This item is designed to fit all vehicles.",
      product_id: product_id
    }
  end

  def vehicle_not_specified_response
    { fits: false, status: "vehicle_not_specified", badge_text: "Select Vehicle", badge_color: "warning" }
  end

  def exact_fit_response(fitment, target_vehicle, product_id)
    {
      fits: true,
      fitment_type: fitment.fitment_type,
      badge_text: "Guaranteed Exact Fit for #{target_vehicle.display_name}",
      badge_color: "success",
      notes: fitment.fitment_notes,
      position: fitment.position,
      product_id: product_id,
      vehicle: target_vehicle.to_h
    }
  end

  def no_fit_response(target_vehicle, product_id)
    {
      fits: false,
      fitment_type: "none",
      badge_text: "Does NOT fit #{target_vehicle.display_name}",
      badge_color: "critical",
      notes: "This part is not compatible with your selected vehicle.",
      product_id: product_id,
      vehicle: target_vehicle.to_h
    }
  end

  def matching_vehicle_ids(year:, make:, model:, trim: nil, engine: nil)
    vehicles = Vehicle.by_year(year).by_make(make).by_model(model)
    vehicles = vehicles.by_trim(trim) if trim.present?
    vehicles = vehicles.by_engine(engine) if engine.present?
    vehicles.pluck(:id)
  end

  # Unique, deterministically ordered product IDs across both specific and
  # universal fitments, so pages are stable and a product listed in both sets
  # appears only once.
  def matching_product_ids(vehicle_ids)
    specific_ids = @shop.vehicle_product_fitments.where(vehicle_id: vehicle_ids).pluck(:product_id)
    universal_ids = @shop.vehicle_product_fitments.universal.pluck(:product_id)
    (specific_ids + universal_ids).uniq.sort
  end

  # Fetches full fitment rows only for the requested page and returns one
  # payload per product (a product may have both a specific and a universal
  # row; the first is kept so each product appears once).
  def build_products(paged_ids)
    return [] if paged_ids.empty?

    fitments = @shop.vehicle_product_fitments.where(product_id: paged_ids).order(:product_id)
    by_product = fitments.to_a.group_by(&:product_id)
    paged_ids.filter_map { |pid| by_product[pid]&.first }.map { |fitment| product_payload(fitment) }
  end

  def product_payload(fitment)
    {
      product_id: fitment.product_id,
      product_handle: fitment.product_handle,
      product_title: fitment.product_title,
      sku: fitment.sku,
      brand: fitment.brand,
      category: fitment.category,
      price_cents: fitment.price_cents,
      short_description: fitment.short_description,
      universal: fitment.universal_fit?,
      fitment_notes: fitment.fitment_notes,
      position: fitment.position
    }
  end

  def cache_fetch(key, &)
    full_key = "vsp/shop/#{@shop.id}/v#{@version}/#{key}"
    Rails.cache.fetch(full_key, expires_in: CACHE_TTL, &)
  end
end
