class Admin::VehicleAttributesController < ApplicationController
  def index
    @shop = current_shop
    @vehicle_attributes = @shop.vehicle_attributes.includes(:vehicle_attribute_values).order(:sort_order)
  end

  def create
    @shop = current_shop
    @vehicle_attribute = @shop.vehicle_attributes.build(vehicle_attribute_params)

    if @vehicle_attribute.save
      render json: @vehicle_attribute, status: :created
    else
      render json: { errors: @vehicle_attribute.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @shop = current_shop
    @vehicle_attribute = @shop.vehicle_attributes.find(params[:id])

    if @vehicle_attribute.update(vehicle_attribute_params)
      render json: @vehicle_attribute
    else
      render json: { errors: @vehicle_attribute.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @shop = current_shop
    @vehicle_attribute = @shop.vehicle_attributes.find(params[:id])
    @vehicle_attribute.destroy
    render json: { status: "deleted" }
  end

  private

  def vehicle_attribute_params
    params.require(:vehicle_attribute).permit(:attribute_type, :label, :description, :sort_order, :active, vehicle_attribute_values_attributes: [:id, :value, :display_name, :sort_order, :active, :_destroy])
  end
end
