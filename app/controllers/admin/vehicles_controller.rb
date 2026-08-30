module Admin
  class VehiclesController < BaseController
    def index
      @vehicles = Vehicle.active

      @vehicles = @vehicles.by_year(params[:year]) if params[:year].present?

      @vehicles = @vehicles.by_make(params[:make]) if params[:make].present?

      @vehicles = @vehicles.by_model(params[:model]) if params[:model].present?

      if params[:query].present?
        q = "%#{params[:query].strip.downcase}%"
        @vehicles = @vehicles.where(
          "LOWER(make) LIKE :q OR LOWER(model) LIKE :q OR LOWER(trim) LIKE :q OR LOWER(engine) LIKE :q", q: q
        )
      end

      @page = (params[:page] || 1).to_i
      @per_page = 25
      @total_count = @vehicles.count
      @vehicles = @vehicles.order(year: :desc, make: :asc, model: :asc).offset((@page - 1) * @per_page).limit(@per_page)

      @distinct_years = Vehicle.distinct_years
    end

    def show
      @vehicle = Vehicle.find(params[:id])
      @associated_fitments = current_shop.vehicle_product_fitments.where(vehicle_id: @vehicle.id)
    end

    def ymm_tree
      render json: VehicleHierarchyService.full_tree
    end

    def years
      render json: Vehicle.distinct_years
    end

    def makes
      render json: Vehicle.distinct_makes_for_year(params[:year])
    end

    def models
      render json: Vehicle.distinct_models_for(year: params[:year], make: params[:make])
    end

    def trims
      render json: Vehicle.distinct_trims_for(year: params[:year], make: params[:make], model: params[:model])
    end

    def engines
      render json: Vehicle.distinct_engines_for(year: params[:year], make: params[:make], model: params[:model],
                                                trim: params[:trim])
    end
  end
end
