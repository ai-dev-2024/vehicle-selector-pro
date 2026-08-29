class CreateShops < ActiveRecord::Migration[7.1]
  def change
    create_table :shops do |t|
      t.string :shopify_domain, null: false
      t.string :shopify_token, null: false
      t.string :access_scopes, default: "read_products,write_products"
      t.string :shopify_id
      t.string :email
      t.string :name
      t.string :currency, default: "USD"
      t.string :iana_timezone, default: "America/New_York"
      t.boolean :active, default: true, null: false
      t.datetime :uninstalled_at

      t.timestamps
    end

    add_index :shops, :shopify_domain, unique: true
    add_index :shops, :active
  end
end
