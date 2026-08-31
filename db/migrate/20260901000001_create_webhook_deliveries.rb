class CreateWebhookDeliveries < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_deliveries do |t|
      t.string :shop_domain, null: false
      t.string :topic, null: false
      t.string :webhook_id, null: false
      t.string :processed_by
      t.string :status, default: "processed", null: false
      t.text :error_details
      t.datetime :processed_at, null: false
      t.timestamps
    end

    add_index :webhook_deliveries, %i[shop_domain webhook_id], unique: true,
                                                               name: "index_webhook_deliveries_on_shop_and_webhook_id"
    add_index :webhook_deliveries, :processed_at
  end
end
