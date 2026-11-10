# Resolves the shop that backs the public /demo storefront and the development
# preview harness: the shop with the demo domain, which the seeds populate.
# Used by both DemoApiController and StorefrontPreviewController.
class DemoShopResolver
  def self.resolve
    demo_domain = ENV.fetch("SHOPIFY_STORE_DOMAIN", "vehicle-selector-pro.myshopify.com")
    shop = Shop.find_by(shopify_domain: demo_domain)

    # The /demo pages and /demo/api are public and unauthenticated. Outside
    # local development they may only ever render the demo shop: falling back
    # to "whichever shop has data" would publish a real merchant's catalog.
    return shop if shop || !Rails.env.local?

    # Local convenience: an unseeded database still renders something.
    Shop.active.left_joins(:vehicle_product_fitments)
        .group(:id).order(Arel.sql("COUNT(vehicle_product_fitments.id) DESC")).first ||
      Shop.active.first || Shop.first
  end
end
