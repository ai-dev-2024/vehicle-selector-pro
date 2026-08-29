class CreateProductVehicleAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :product_vehicle_attributes do |t|
      t.references :product, null: false, foreign_key: true
      t.references :vehicle_attribute, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.string :value, null: false
      t.string :metafield_id
      t.datetime :synced_at

      t.timestamps
    end

    add_index :product_vehicle_attributes, [:product_id, :vehicle_attribute_id], unique: true, name: "index_product_vehicle_attrs_unique"
    add_index :product_vehicle_attributes, [:shop_id, :vehicle_attribute_id]
  end
end
