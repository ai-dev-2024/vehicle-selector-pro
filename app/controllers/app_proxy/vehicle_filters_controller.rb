module AppProxy
  class VehicleFiltersController < BaseController
    # GET /apps/vehicle-selector/years
    def years
      available_years = fitment_search_service.years
      render json: {
        success: true,
        years: available_years,
        count: available_years.size
      }
    end

    # GET /apps/vehicle-selector/makes?year=2024
    def makes
      year = params[:year]
      return render json: { success: false, error: "Parameter 'year' is required" }, status: :bad_request if year.blank?

      available_makes = fitment_search_service.makes(year: year)
      render json: {
        success: true,
        year: year.to_i,
        makes: available_makes,
        count: available_makes.size
      }
    end

    # GET /apps/vehicle-selector/models?year=2024&make=Ford
    def models
      year = params[:year]
      make = params[:make]

      if year.blank? || make.blank?
        return render json: { success: false, error: "Parameters 'year' and 'make' are required" }, status: :bad_request
      end

      available_models = fitment_search_service.models(year: year, make: make)
      render json: {
        success: true,
        year: year.to_i,
        make: make,
        models: available_models,
        count: available_models.size
      }
    end

    # GET /apps/vehicle-selector/trims?year=2024&make=Ford&model=F-150
    def trims
      year = params[:year]
      make = params[:make]
      model = params[:model]

      if year.blank? || make.blank? || model.blank?
        return render json: { success: false, error: "Parameters 'year', 'make', and 'model' are required" },
                      status: :bad_request
      end

      available_trims = fitment_search_service.trims(year: year, make: make, model: model)
      render json: {
        success: true,
        year: year.to_i,
        make: make,
        model: model,
        trims: available_trims,
        count: available_trims.size
      }
    end

    # GET /apps/vehicle-selector/engines?year=2024&make=Ford&model=F-150&trim=Lariat
    def engines
      year = params[:year]
      make = params[:make]
      model = params[:model]
      trim = params[:trim]

      if year.blank? || make.blank? || model.blank?
        return render json: { success: false, error: "Parameters 'year', 'make', and 'model' are required" },
                      status: :bad_request
      end

      available_engines = fitment_search_service.engines(year: year, make: make, model: model, trim: trim)
      render json: {
        success: true,
        year: year.to_i,
        make: make,
        model: model,
        trim: trim,
        engines: available_engines,
        count: available_engines.size
      }
    end

    # GET /apps/vehicle-selector/search?year=2024&make=Ford&model=F-150&trim=Lariat&engine=3.5L
    # Also supports ?oe=<OE number> which resolves products by factory part
    # number cross-reference instead of by vehicle.
    def search
      oe = params[:oe].to_s.strip
      return render_oe_search(oe) if oe.present?

      year = params[:year]
      make = params[:make]
      model = params[:model]
      trim = params[:trim]
      engine = params[:engine]

      if year.blank? || make.blank? || model.blank?
        return render json: { success: false, error: "At minimum 'year', 'make', and 'model' are required" },
                      status: :bad_request
      end

      results = fitment_search_service.search_products(
        year: year,
        make: make,
        model: model,
        trim: trim,
        engine: engine,
        limit: params[:limit] || 50,
        page: params[:page] || 1
      )

      render json: {
        success: true,
        data: results
      }
    end

    private

    def render_oe_search(oe_term)
      product_ids = OeNumber.product_ids_for(current_shop, oe_term)
      products = current_shop.vehicle_product_fitments
                             .where(product_id: product_ids)
                             .includes(:vehicle)
                             .order(:product_id)
                             .map { |f| fitment_search_service.product_payload(f) }
      render json: {
        success: true,
        data: {
          vehicle: { oe: oe_term },
          total_count: product_ids.size,
          product_ids: product_ids,
          numeric_product_ids: product_ids.map { |pid| pid.to_s.gsub("gid://shopify/Product/", "") },
          products: products
        }
      }
    end
  end
end
