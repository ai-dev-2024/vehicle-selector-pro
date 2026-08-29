module Admin
  class ProductFitmentsController < BaseController
    before_action :set_fitment, only: [:edit, :update, :destroy]

    def index
      @fitments = current_shop.vehicle_product_fitments.includes(:vehicle)

      if params[:query].present?
        q = "%#{params[:query].strip.downcase}%"
        @fitments = @fitments.joins('LEFT JOIN vehicles ON vehicles.id = vehicle_product_fitments.vehicle_id')
                             .where('LOWER(product_title) LIKE :q OR LOWER(sku) LIKE :q OR LOWER(product_handle) LIKE :q OR LOWER(vehicles.make) LIKE :q OR LOWER(vehicles.model) LIKE :q', q: q)
      end

      if params[:fitment_type].present?
        if params[:fitment_type] == 'universal'
          @fitments = @fitments.universal
        else
          @fitments = @fitments.specific
        end
      end

      @page = (params[:page] || 1).to_i
      @per_page = 20
      @total_count = @fitments.count
      @fitments = @fitments.order(created_at: :desc).offset((@page - 1) * @per_page).limit(@per_page)
    end

    def new
      @fitment = current_shop.vehicle_product_fitments.new
      @years = Vehicle.distinct_years
    end

    def create
      if params[:universal_fit] == '1' || params[:universal_fit] == 'true'
        @fitment = current_shop.vehicle_product_fitments.new(universal_fitment_params)
        @fitment.universal_fit = true
        @fitment.vehicle = nil
      else
        @fitment = current_shop.vehicle_product_fitments.new(fitment_params)
        @fitment.universal_fit = false
      end

      if @fitment.save
        redirect_to admin_product_fitments_path, notice: "Fitment successfully assigned to #{@fitment.product_title.presence || @fitment.product_id}!"
      else
        @years = Vehicle.distinct_years
        flash.now[:alert] = @fitment.errors.full_messages.join(', ')
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @years = Vehicle.distinct_years
    end

    def update
      if @fitment.update(fitment_params)
        redirect_to admin_product_fitments_path, notice: "Fitment successfully updated."
      else
        @years = Vehicle.distinct_years
        flash.now[:alert] = @fitment.errors.full_messages.join(', ')
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      product_id = @fitment.product_id
      @fitment.destroy
      redirect_to admin_product_fitments_path, notice: "Fitment mapping removed."
    end

    # POST /admin/product_fitments/bulk_assign
    def bulk_assign
      product_id = params[:product_id]
      product_title = params[:product_title]
      vehicle_ids = params[:vehicle_ids] || []

      if product_id.blank? || vehicle_ids.empty?
        return redirect_to new_admin_product_fitment_path, alert: "Product ID and at least one vehicle must be selected."
      end

      created_count = 0
      vehicle_ids.each do |vid|
        fitment = current_shop.vehicle_product_fitments.find_or_initialize_by(
          product_id: product_id,
          vehicle_id: vid
        )
        fitment.product_title = product_title if product_title.present?
        fitment.product_handle = params[:product_handle] if params[:product_handle].present?
        fitment.fitment_notes = params[:fitment_notes] if params[:fitment_notes].present?
        fitment.position = params[:position] if params[:position].present?
        fitment.universal_fit = false

        if fitment.save
          created_count += 1
        end
      end

      redirect_to admin_product_fitments_path, notice: "Successfully assigned #{created_count} vehicles to #{product_title.presence || product_id}!"
    end

    private

    def set_fitment
      @fitment = current_shop.vehicle_product_fitments.find(params[:id])
    end

    def fitment_params
      params.require(:vehicle_product_fitment).permit(
        :product_id, :product_handle, :product_title, :sku, :vehicle_id,
        :fitment_type, :fitment_notes, :position, :quantity_required
      )
    end

    def universal_fitment_params
      params.require(:vehicle_product_fitment).permit(
        :product_id, :product_handle, :product_title, :sku,
        :fitment_notes, :position
      )
    end
  end
end
