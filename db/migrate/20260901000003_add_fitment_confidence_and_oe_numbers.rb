class AddFitmentConfidenceAndOeNumbers < ActiveRecord::Migration[7.1]
  def change
    # Confidence score 0..1 computed from fitment_type at write time; kept as a
    # column so storefront queries can sort/filter without recalculating.
    add_column :vehicle_product_fitments, :confidence_score, :decimal, precision: 3, scale: 2, default: 1.0, null: false

    # Original Equipment (OE) part numbers per product — the cross-reference
    # that lets shoppers search by their vehicle's factory part number.
    create_table :oe_numbers do |t|
      t.references :shop, null: false, foreign_key: { on_delete: :cascade }
      t.string :product_id, null: false
      t.string :oe_number, null: false
      t.string :source, default: "manual"
      t.timestamps
    end

    add_index :oe_numbers, %i[shop_id oe_number], unique: true,
                                                  name: "index_oe_numbers_on_shop_and_oe_number"
    add_index :oe_numbers, %i[shop_id product_id], name: "index_oe_numbers_on_shop_and_product_id"
  end
end
