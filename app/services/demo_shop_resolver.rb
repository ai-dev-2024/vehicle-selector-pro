# Resolves the shop that backs the public /demo storefront and the development
# preview harness. The demo must always render the shop that actually holds the
# seeded demo catalog: a real store can hold both an OAuth-installed shop row
# and the seeded demo row, so we prefer the demo domain, then the active shop
# with the most fitments, so the public demo pages never render an empty
# catalog. Used by both DemoApiController and StorefrontPreviewController.
class DemoShopResolver
  def self.resolve
    demo_domain = ENV.fetch("SHOPIFY_STORE_DOMAIN", "vehicle-selector-pro.myshopify.com")
    Shop.find_by(shopify_domain: demo_domain) ||
      Shop.active.left_joins(:vehicle_product_fitments)
          .group(:id).order(Arel.sql("COUNT(vehicle_product_fitments.id) DESC")).first ||
      Shop.active.first || Shop.first
  end
end
