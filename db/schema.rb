# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_09_01_000007) do
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

  create_table "fitment_analytics", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.string "dimension", default: "all", null: false
    t.string "metric", default: "checks", null: false
    t.bigint "value", default: 0, null: false
    t.date "day", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "dimension_value"
    t.index ["shop_id", "dimension", "dimension_value", "metric", "day"], name: "index_fitment_analytics_shop_dim_val_metric_day", unique: true
    t.index ["shop_id"], name: "index_fitment_analytics_on_shop_id"
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

  create_table "oe_numbers", force: :cascade do |t|
    t.integer "shop_id", null: false
    t.string "product_id", null: false
    t.string "oe_number", null: false
    t.string "source", default: "manual"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "oe_number"], name: "index_oe_numbers_on_shop_and_oe_number", unique: true
    t.index ["shop_id", "product_id"], name: "index_oe_numbers_on_shop_and_product_id"
    t.index ["shop_id"], name: "index_oe_numbers_on_shop_id"
  end

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
    t.string "billing_plan", default: "free", null: false
    t.datetime "billing_activated_at"
    t.datetime "billing_expires_at"
    t.index ["active"], name: "index_shops_on_active"
    t.index ["shopify_domain"], name: "index_shops_on_shopify_domain", unique: true
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.binary "key", limit: 1024, null: false
    t.binary "value", limit: 536870912, null: false
    t.datetime "created_at", null: false
    t.integer "key_hash", limit: 8, null: false
    t.integer "byte_size", limit: 4, null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
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
    t.string "brand"
    t.string "category"
    t.integer "price_cents"
    t.string "short_description"
    t.string "product_image"
    t.decimal "confidence_score", precision: 3, scale: 2, default: "1.0", null: false
    t.index ["product_id", "shop_id"], name: "index_fitments_product_shop"
    t.index ["product_id"], name: "index_vehicle_product_fitments_on_product_id"
    t.index ["shop_id", "fitment_type"], name: "index_fitments_shop_fitment_type"
    t.index ["shop_id", "product_id"], name: "index_vehicle_product_fitments_on_shop_id_and_product_id"
    t.index ["shop_id", "synced_to_metafield", "last_synced_at"], name: "index_fitments_shop_synced_last_synced"
    t.index ["shop_id", "synced_to_metafield"], name: "index_vehicle_product_fitments_on_shop_id_and_synced"
    t.index ["shop_id", "universal_fit", "product_id"], name: "index_fitments_shop_universal_product"
    t.index ["shop_id", "universal_fit"], name: "index_vehicle_product_fitments_on_shop_id_and_universal_fit"
    t.index ["shop_id", "vehicle_id", "product_id"], name: "index_fitments_on_shop_vehicle_product_unique", unique: true
    t.index ["shop_id", "vehicle_id"], name: "index_vehicle_product_fitments_on_shop_id_and_vehicle_id"
    t.index ["shop_id"], name: "index_vehicle_product_fitments_on_shop_id"
    t.index ["vehicle_id"], name: "index_vehicle_product_fitments_on_vehicle_id"
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
    t.index ["make", "model"], name: "index_vehicles_on_make_and_model"
    t.index ["make"], name: "index_vehicles_on_make"
    t.index ["model"], name: "index_vehicles_on_model"
    t.index ["year", "make", "model", "trim", "engine"], name: "index_vehicles_on_ymmte_unique", unique: true
    t.index ["year", "make", "model"], name: "index_vehicles_on_year_and_make_and_model"
    t.index ["year", "make"], name: "index_vehicles_on_year_and_make"
    t.index ["year"], name: "index_vehicles_on_year"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.string "shop_domain", null: false
    t.string "topic", null: false
    t.string "webhook_id", null: false
    t.string "processed_by"
    t.string "status", default: "processed", null: false
    t.text "error_details"
    t.datetime "processed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processed_at"], name: "index_webhook_deliveries_on_processed_at"
    t.index ["shop_domain", "webhook_id"], name: "index_webhook_deliveries_on_shop_and_webhook_id", unique: true
  end

  add_foreign_key "app_settings", "shops", on_delete: :cascade
  add_foreign_key "fitment_analytics", "shops", on_delete: :cascade
  add_foreign_key "metafield_sync_logs", "shops", on_delete: :cascade
  add_foreign_key "oe_numbers", "shops", on_delete: :cascade
  add_foreign_key "vehicle_product_fitments", "shops", on_delete: :cascade
  add_foreign_key "vehicle_product_fitments", "vehicles", on_delete: :cascade
end
