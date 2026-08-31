class AddPerformanceIndexes < ActiveRecord::Migration[7.1]
  def change
    # Fitment search: filter by shop + universal flag, then join vehicle rows.
    add_index :vehicle_product_fitments, %i[shop_id universal_fit product_id],
              name: "index_fitments_shop_universal_product", if_not_exists: true
    # Sync status sweep (pending_sync queries in MetafieldSyncService).
    add_index :vehicle_product_fitments, %i[shop_id synced_to_metafield last_synced_at],
              name: "index_fitments_shop_synced_last_synced", if_not_exists: true
    # Webhook metadata refresh walks fitments by product_id per shop.
    add_index :vehicle_product_fitments, %i[product_id shop_id],
              name: "index_fitments_product_shop", if_not_exists: true
    # Vehicle cascade dropdowns filter on year then make then model.
    add_index :vehicles, %i[make model], name: "index_vehicles_on_make_and_model", if_not_exists: true
  end
end
