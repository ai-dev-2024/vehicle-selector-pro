class HomeController < ApplicationController
  def index
    @shop = current_shop
    @vehicle_attributes_count = @shop.vehicle_attributes.count if @shop
    @products_count = @shop.products.count if @shop
  end
end
