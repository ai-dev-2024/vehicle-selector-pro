module AppProxy
  class GarageController < BaseController
    # GET /apps/vehicle-selector/garage?vehicle_ids=1,2,3
    def index
      vehicle_ids = params[:vehicle_ids].to_s.split(",").map(&:strip).compact_blank

      return render json: { success: true, vehicles: [] } if vehicle_ids.empty?

      vehicles = Vehicle.where(id: vehicle_ids).map(&:to_h)

      render json: {
        success: true,
        vehicles: vehicles
      }
    end
  end
end
