class AddDimensionValueToFitmentAnalytics < ActiveRecord::Migration[7.1]
  def change
    add_column :fitment_analytics, :dimension_value, :string
    # The per-day aggregate is now keyed by (shop, dimension, dimension_value,
    # metric, day) so makes and years are stored as their own rows instead of
    # colliding under a bare dimension name.
    # Rails can't reverse a bare name-based remove_index, so disassociate the
    # old index's columns first (making this migration reversible) then rebuild
    # the unique index to include the new dimension_value column.
    remove_index :fitment_analytics, column: %i[shop_id dimension metric day]
    add_index :fitment_analytics, %i[shop_id dimension dimension_value metric day],
              name: "index_fitment_analytics_shop_dim_val_metric_day",
              unique: true
  end
end
