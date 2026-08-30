class CreateVehicleProductFitments < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_product_fitments do |t|
      t.references :shop, null: false, foreign_key: { on_delete: :cascade }
      t.references :vehicle, null: true, foreign_key: { on_delete: :cascade }
      t.string :product_id, null: false # Shopify Product GID/ID
      t.string :product_handle
      t.string :product_title
      t.string :variant_id # Optional variant specific fitment
      t.string :sku
      t.boolean :universal_fit, default: false, null: false
      t.string :fitment_type, default: "direct_fit" # direct_fit, universal, custom, modified
      t.text :fitment_notes # e.g. "Fits Front Axle only", "Requires 2-inch lift"
      t.string :position # Front, Rear, Left, Right, All
      t.string :quantity_required
      t.boolean :synced_to_metafield, default: false, null: false
      t.datetime :last_synced_at

      t.timestamps
    end

    add_index :vehicle_product_fitments, %i[shop_id product_id]
    add_index :vehicle_product_fitments, %i[shop_id vehicle_id]
    add_index :vehicle_product_fitments, %i[shop_id vehicle_id product_id], unique: true,
                                                                            name: "index_fitments_on_shop_vehicle_product_unique"
    add_index :vehicle_product_fitments, %i[shop_id universal_fit]
    add_index :vehicle_product_fitments, %i[shop_id synced_to_metafield]
    add_index :vehicle_product_fitments, :product_id
  end
end
