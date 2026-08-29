class CreateVehicleAttributes < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_attributes do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :attribute_type, null: false, index: true
      t.string :label, null: false
      t.text :description
      t.integer :sort_order, default: 0
      t.boolean :active, default: true, index: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :vehicle_attributes, [:shop_id, :attribute_type], unique: true
  end
end
