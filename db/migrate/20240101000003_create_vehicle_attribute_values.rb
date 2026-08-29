class CreateVehicleAttributeValues < ActiveRecord::Migration[7.1]
  def change
    create_table :vehicle_attribute_values do |t|
      t.references :vehicle_attribute, null: false, foreign_key: true
      t.references :shop, null: false, foreign_key: true
      t.string :value, null: false
      t.string :display_name
      t.integer :sort_order, default: 0
      t.boolean :active, default: true
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :vehicle_attribute_values, [:vehicle_attribute_id, :value], unique: true
    add_index :vehicle_attribute_values, [:shop_id, :active]
  end
end
