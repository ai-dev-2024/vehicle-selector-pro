class AddBillingPlanAndAnalytics < ActiveRecord::Migration[7.1]
  def change
    # Billing foundation (beyond the original spec): which Shopify Billing
    # plan this shop is on, gating bulk imports / advanced features.
    add_column :shops, :billing_plan, :string, default: "free", null: false
    add_column :shops, :billing_activated_at, :datetime
    add_column :shops, :billing_expires_at, :datetime

    # Analytics foundation: one row per storefront fitment check so merchants
    # can see which vehicles actually convert. Rows are aggregates written by a
    # background job, not raw per-request logs.
    create_table :fitment_analytics do |t|
      t.references :shop, null: false, foreign_key: { on_delete: :cascade }
      t.string :dimension, null: false, default: "all"   # e.g. "all", "Ford", "2024"
      t.string :metric, null: false, default: "checks"   # "checks", "fits", "no_fit"
      t.bigint :value, null: false, default: 0
      t.date :day, null: false
      t.timestamps
    end

    add_index :fitment_analytics, %i[shop_id dimension metric day], unique: true,
                                                                    name: "index_fitment_analytics_shop_dim_metric_day"
  end
end
