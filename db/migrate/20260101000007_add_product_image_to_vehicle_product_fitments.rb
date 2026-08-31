class AddProductImageToVehicleProductFitments < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicle_product_fitments, :product_image, :string
  end
end
