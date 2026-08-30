module AppProxy
  class FitmentsController < BaseController
    # GET /apps/vehicle-selector/check_fitment?product_id=123&year=2024&make=Ford&model=F-150...
    def check
      product_id = params[:product_id]
      return render json: { success: false, error: "Parameter 'product_id' is required" }, status: :bad_request if product_id.blank?

      fitment_result = fitment_search_service.check_fitment(
        product_id: product_id,
        vehicle_id: params[:vehicle_id],
        year: params[:year],
        make: params[:make],
        model: params[:model],
        trim: params[:trim],
        engine: params[:engine]
      )

      render json: {
        success: true,
        data: fitment_result
      }
    end

    # GET /apps/vehicle-selector/product_fitments?product_id=123
    def product_fitments
      product_id = params[:product_id]
      return render json: { success: false, error: "Parameter 'product_id' is required" }, status: :bad_request if product_id.blank?

      fitments = current_shop.vehicle_product_fitments
                             .where(product_id: FitmentSearchService.product_id_variants(product_id))
                             .includes(:vehicle)
      render json: {
        success: true,
        product_id: product_id,
        universal: fitments.any?(&:universal_fit?),
        fitments: fitments.map(&:to_fitment_hash)
      }
    end
  end
end
