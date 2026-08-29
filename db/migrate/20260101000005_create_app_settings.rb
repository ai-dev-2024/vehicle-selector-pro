class CreateAppSettings < ActiveRecord::Migration[7.1]
  def change
    create_table :app_settings do |t|
      t.references :shop, null: false, foreign_key: { on_delete: :cascade }
      t.string :widget_title, default: "Select Your Vehicle"
      t.string :widget_subtitle, default: "Find parts guaranteed to fit your exact vehicle"
      t.string :layout_style, default: "horizontal" # horizontal, vertical, popup
      t.string :primary_color, default: "#1a73e8"
      t.string :button_label, default: "Find Parts"
      t.string :reset_label, default: "Reset Vehicle"
      t.boolean :enable_trim, default: true, null: false
      t.boolean :enable_engine, default: true, null: false
      t.boolean :enable_garage, default: true, null: false
      t.integer :max_garage_vehicles, default: 5
      t.boolean :auto_filter_collections, default: true, null: false
      t.string :filter_query_param, default: "filter.v.m.custom.vehicle_fitment"
      t.text :fitment_guarantee_text, default: "100% Fitment Guaranteed. If this part doesn't fit your verified vehicle, returns are free."
      t.boolean :show_badge_on_product_page, default: true, null: false

      t.timestamps
    end

    add_index :app_settings, :shop_id, unique: true
  end
end
