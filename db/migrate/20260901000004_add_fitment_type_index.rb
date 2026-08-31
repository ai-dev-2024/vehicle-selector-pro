class AddFitmentTypeIndex < ActiveRecord::Migration[7.1]
  def change
    add_index :vehicle_product_fitments, %i[shop_id fitment_type],
              name: "index_fitments_shop_fitment_type", if_not_exists: true
  end
end
