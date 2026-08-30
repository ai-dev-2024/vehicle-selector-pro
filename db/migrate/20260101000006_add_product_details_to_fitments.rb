class AddProductDetailsToFitments < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicle_product_fitments, :brand, :string
    add_column :vehicle_product_fitments, :category, :string
    add_column :vehicle_product_fitments, :price_cents, :integer
    add_column :vehicle_product_fitments, :short_description, :string
  end
end
