class CreateProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :products do |t|
      t.references :shop, null: false, foreign_key: true
      t.string :shopify_product_id, null: false, index: true
      t.string :title, null: false
      t.text :description
      t.jsonb :product_data, default: {}
      t.datetime :synced_at
      t.datetime :last_metafield_sync
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :products, [:shop_id, :shopify_product_id], unique: true
  end
end
