class Admin::ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update]

  def index
    @shop = current_shop
    @products = @shop.products.page(params[:page]).per(20)
  end

  def show
    @shop = current_shop
    @vehicle_attributes = @product.product_vehicle_attributes.includes(:vehicle_attribute)
  end

  def edit
    @shop = current_shop
    @available_attributes = @shop.vehicle_attributes.active
    @selected_attributes = @product.product_vehicle_attributes.index_by(&:vehicle_attribute_id)
  end

  def update
    @shop = current_shop
    if @product.update(product_params)
      sync_vehicle_attributes
      redirect_to admin_product_path(@product), notice: "Product updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:title, :description, product_vehicle_attributes_attributes: [:id, :vehicle_attribute_id, :value, :_destroy])
  end

  def sync_vehicle_attributes
    # Sync to Shopify metafields
    SyncProductAttributesJob.perform_later(@product.id, @shop.id)
  end
end
