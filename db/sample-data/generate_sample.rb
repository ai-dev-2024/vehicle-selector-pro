# One-off script: regenerate the bulk-fitment sample CSV from the seeded
# demo catalog. Run with:
#   bundle exec rails runner db/sample-data/generate_sample.rb
require "csv"

shop = DemoShopResolver.resolve
rows = shop.vehicle_product_fitments.includes(:vehicle)
           .order(:product_id, "vehicles.year").map do |f|
  if f.universal_fit?
    [f.product_id, f.product_handle, f.product_title, f.sku, "", "", "", "", "",
     "true", f.fitment_notes, f.position]
  else
    [f.product_id, f.product_handle, f.product_title, f.sku,
     f.vehicle&.year, f.vehicle&.make, f.vehicle&.model, f.vehicle&.trim,
     f.vehicle&.engine, "false", f.fitment_notes, f.position]
  end
end

CSV.open("db/sample-data/bulk_fitment_sample.csv", "w") do |csv|
  csv << %w[product_id product_handle product_title sku year make model trim engine universal notes position]
  rows.each { |r| csv << r }
end

puts "Wrote #{rows.size} fitment rows to db/sample-data/bulk_fitment_sample.csv"
