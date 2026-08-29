# This file is auto-generated from the current state of the database.
ActiveRecord::Schema[7.1].define(version: 2026_01_01_000005) do
  create_table "shops", force: :cascade do |t|
    t.string "shopify_domain", null: false
    t.string "shopify_token", null: false
    t.string "access_scopes", default: "read_products,write_products"
    t.string "shopify_id"
    t.string "email"
    t.string "name"
    t.string "currency", default: "USD"
    t.string "iana_timezone", default: "America/New_York"
    t.boolean "active", default: true, null: false
    t.datetime "uninstalled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_shops_on_active"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "vehicles", force: :cascade do |t|
    t.integer "year", null: false
    t.string "make", null: false
    t.string "model", null: false
    t.string "trim"
    t.string "engine"
    t.string "fuel_type"
    t.string "transmission"
    t.string "drivetrain"
    t.string "body_style"
    t.string "standard_id"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["make"], name: "index_vehicles_on_make"
    t.index ["model"], name: "index_vehicles_on_model"
    t.index ["year", "make", "model", "trim", "engine"], name: "index_vehicles_on_ymmte_unique", unique: true
    t.index ["year", "make", "model"], name: "index_vehicles_on_year_and_make_and_model"
    t.index ["year", "make"], name: "index_vehicles_on_year_and_make"
    t.index ["year"], name: "index_vehicles_on_year"
  end

  create_table "vehicle_product_fitments", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.integer "vehicle_id"
    t.string "product_id", null: false
    t.string "product_handle"
    t.string "product_title"
    t.string "variant_id"
    t.string "sku"
    t.boolean "universal_fit", default: false, null: false
    t.string "fitment_type", default: "direct_fit"
    t.text "fitment_notes"
    t.string "position"
    t.string "quantity_required"
    t.boolean "synced_to_metafield", default: false, null: false
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_vehicle_product_fitments_on_product_id"
    t.index ["shop_id", "product_id"], name: "index_vehicle_product_fitments_on_shop_id_and_product_id"
    t.index ["shop_id", "synced_to_metafield"], name: "index_vehicle_product_fitments_on_shop_id_and_synced"
    t.index ["shop_id", "universal_fit"], name: "index_vehicle_product_fitments_on_shop_id_and_universal_fit"
    t.index ["shop_id", "vehicle_id", "product_id"], name: "index_fitments_on_shop_vehicle_product_unique", unique: true
    t.index ["shop_id", "vehicle_id"], name: "index_vehicle_product_fitments_on_shop_id_and_vehicle_id"
    t.index ["shop_id"], name: "index_vehicle_product_fitments_on_shop_id"
    t.index ["vehicle_id"], name: "index_vehicle_product_fitments_on_vehicle_id"
  end

  create_table "metafield_sync_logs", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.string "sync_type", default: "batch"
    t.string "status", default: "pending"
    t.integer "total_products", default: 0
    t.integer "synced_products", default: 0
    t.integer "failed_products", default: 0
    t.text "error_details"
    t.json "metadata"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "created_at"], name: "index_metafield_sync_logs_on_shop_id_and_created_at"
    t.index ["shop_id", "status"], name: "index_metafield_sync_logs_on_shop_id_and_status"
    t.index ["shop_id"], name: "index_metafield_sync_logs_on_shop_id"
  end

  create_table "app_settings", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.string "widget_title", default: "Select Your Vehicle"
    t.string "widget_subtitle", default: "Find parts guaranteed to fit your exact vehicle"
    t.string "layout_style", default: "horizontal"
    t.string "primary_color", default: "#1a73e8"
    t.string "button_label", default: "Find Parts"
    t.string "reset_label", default: "Reset Vehicle"
    t.boolean "enable_trim", default: true, null: false
    t.boolean "enable_engine", default: true, null: false
    t.boolean "enable_garage", default: true, null: false
    t.integer "max_garage_vehicles", default: 5
    t.boolean "auto_filter_collections", default: true, null: false
    t.string "filter_query_param", default: "filter.v.m.custom.vehicle_fitment"
    t.text "fitment_guarantee_text", default: "100% Fitment Guaranteed. If this part doesn't fit your verified vehicle, returns are free."
    t.boolean "show_badge_on_product_page", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id"], name: "index_app_settings_on_shop_id", unique: true
  end

  add_foreign_key "app_settings", "shops", on_delete: :cascade
  add_foreign_key "metafield_sync_logs", "shops", on_delete: :cascade
  add_foreign_key "vehicle_product_fitments", "shops", on_delete: :cascade
  add_foreign_key "vehicle_product_fitments", "vehicles", on_delete: :cascade
end
