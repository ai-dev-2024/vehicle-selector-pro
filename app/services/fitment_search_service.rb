class FitmentSearchService
  CACHE_TTL = 1.hour

  def self.invalidate_shop_cache(shop_id)
    # Increment shop version token in cache to instantly invalidate all cached queries
    Rails.cache.write("vsp/shop_version/#{shop_id}", Time.current.to_i)
  end

  def self.shop_version(shop_id)
    Rails.cache.fetch("vsp/shop_version/#{shop_id}", expires_in: 24.hours) { 1 }
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
      @shop.vehicles.where(year: year).where('LOWER(make) = ?', make.downcase.strip).distinct.order(:model).pluck(:model)
    end
  end

  def trims(year:, make:, model:)
    return [] if year.blank? || make.blank? || model.blank?
    cache_fetch("trims/#{year}/#{make.downcase}/#{model.downcase}") do
      @shop.vehicles
           .where(year: year)
           .where('LOWER(make) = ?', make.downcase.strip)
           .where('LOWER(model) = ?', model.downcase.strip)
           .where.not(trim: [nil, ''])
           .distinct.order(:trim).pluck(:trim)
    end
  end

  def engines(year:, make:, model:, trim: nil)
    return [] if year.blank? || make.blank? || model.blank?
    cache_key = "engines/#{year}/#{make.downcase}/#{model.downcase}/#{trim.to_s.downcase}"
    cache_fetch(cache_key) do
      query = @shop.vehicles
                   .where(year: year)
                   .where('LOWER(make) = ?', make.downcase.strip)
                   .where('LOWER(model) = ?', model.downcase.strip)
      query = query.where('LOWER(trim) = ?', trim.downcase.strip) if trim.present?
      query.where.not(engine: [nil, '']).distinct.order(:engine).pluck(:engine)
    end
  end

  def search_products(year:, make:, model:, trim: nil, engine: nil, limit: 50, page: 1)
    matching_vehicles = Vehicle.by_year(year).by_make(make).by_model(model)
    matching_vehicles = matching_vehicles.by_trim(trim) if trim.present?
    matching_vehicles = matching_vehicles.by_engine(engine) if engine.present?

    vehicle_ids = matching_vehicles.pluck(:id)

    # 1. Fetch specific fitments
    specific_fitments = @shop.vehicle_product_fitments.where(vehicle_id: vehicle_ids)

    # 2. Fetch universal fitments
    universal_fitments = @shop.vehicle_product_fitments.universal

    all_fitments = (specific_fitments + universal_fitments).uniq(&:product_id)

    product_ids = all_fitments.map(&:product_id).uniq
    numeric_ids = product_ids.map { |pid| pid.to_s.gsub('gid://shopify/Product/', '') }

    # Metafield filter tokens for storefront Liquid integration
    filter_tag = "#{year}|#{make.to_s.downcase}|#{model.to_s.downcase}"

    {
      vehicle: {
        year: year,
        make: make,
        model: model,
        trim: trim,
        engine: engine,
        display_name: [year, make, model, trim, engine].compact_blank.join(' ')
      },
      total_count: all_fitments.size,
      product_ids: product_ids,
      numeric_product_ids: numeric_ids,
      filter_token: filter_tag,
      products: all_fitments.first(limit.to_i).map do |f|
        {
          product_id: f.product_id,
          product_handle: f.product_handle,
          product_title: f.product_title,
          sku: f.sku,
          universal: f.universal_fit?,
          fitment_notes: f.fitment_notes,
          position: f.position
        }
      end
    }
  end

  def check_fitment(product_id:, vehicle_id: nil, year: nil, make: nil, model: nil, trim: nil, engine: nil)
    # Check if universal fit first
    universal = @shop.vehicle_product_fitments.universal.find_by(product_id: product_id.to_s)
    if universal.present?
      return {
        fits: true,
        fitment_type: 'universal',
        badge_text: 'Universal Fit',
        badge_color: 'success',
        notes: universal.fitment_notes.presence || 'This item is designed to fit all vehicles.',
        product_id: product_id
      }
    end

    target_vehicle = nil
    if vehicle_id.present?
      target_vehicle = Vehicle.find_by(id: vehicle_id)
    elsif year.present? && make.present? && model.present?
      query = Vehicle.by_year(year).by_make(make).by_model(model)
      query = query.by_trim(trim) if trim.present?
      query = query.by_engine(engine) if engine.present?
      target_vehicle = query.first
    end

    return { fits: false, status: 'vehicle_not_specified', badge_text: 'Select Vehicle', badge_color: 'warning' } if target_vehicle.nil?

    fitment = @shop.vehicle_product_fitments.find_by(product_id: product_id.to_s, vehicle_id: target_vehicle.id)

    if fitment.present?
      {
        fits: true,
        fitment_type: fitment.fitment_type,
        badge_text: "Guaranteed Exact Fit for #{target_vehicle.display_name}",
        badge_color: 'success',
        notes: fitment.fitment_notes,
        position: fitment.position,
        product_id: product_id,
        vehicle: target_vehicle.to_h
      }
    else
      {
        fits: false,
        fitment_type: 'none',
        badge_text: "Does NOT fit #{target_vehicle.display_name}",
        badge_color: 'critical',
        notes: "This part is not compatible with your selected vehicle.",
        product_id: product_id,
        vehicle: target_vehicle.to_h
      }
    end
  end

  private

  def cache_fetch(key, &block)
    full_key = "vsp/shop/#{@shop.id}/v#{@version}/#{key}"
    Rails.cache.fetch(full_key, expires_in: CACHE_TTL, &block)
  end
end
