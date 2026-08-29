class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.string :shopify_domain, null: false, index: { unique: true }
      t.string :shopify_shop_id, null: false
      t.string :access_token, null: false
      t.string :refresh_token
      t.datetime :access_token_expires_at
      t.jsonb :shop_data, default: {}, null: false
      t.jsonb :scopes, default: [], null: false
      t.datetime :plan_name

      t.timestamps
    end

    add_index :shops, :shopify_shop_id, unique: true
  end
end
