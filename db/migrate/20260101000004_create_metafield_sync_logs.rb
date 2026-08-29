class CreateMetafieldSyncLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :metafield_sync_logs do |t|
      t.references :shop, null: false, foreign_key: { on_delete: :cascade }
      t.string :sync_type, default: "batch" # single, batch, full, webhook
      t.string :status, default: "pending" # pending, in_progress, completed, failed
      t.integer :total_products, default: 0
      t.integer :synced_products, default: 0
      t.integer :failed_products, default: 0
      t.text :error_details
      t.json :metadata
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :metafield_sync_logs, [:shop_id, :status]
    add_index :metafield_sync_logs, [:shop_id, :created_at]
  end
end
