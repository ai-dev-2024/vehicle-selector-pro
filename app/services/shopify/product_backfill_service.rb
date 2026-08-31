module Shopify
  # One-click merchant backfill: walks the shop's products in Shopify via
  # GraphQL (paginated, rate-limit-safe via GraphQLClient) and refreshes the
  # cached title / handle / featured image on any fitment records that have
  # already been mapped in the app. This is the belt-and-suspenders counterpart
  # to the products/update webhook: it lets a merchant upstream their existing
  # catalog in a single action instead of waiting for per-product events.
  #
  # Purely metadata sync — it never creates or deletes fitments, and it only
  # overwrites a field when Shopify actually returns a value (so a blank field
  # in Shopify never wipes what we already have).
  class ProductBackfillService
    PAGE_SIZE = 250
    MAX_PAGES = 40 # hard ceiling (~10k products) so one run can't run away

    QUERY = <<~GRAPHQL.freeze
      query ProductBackfill($cursor: String) {
        products(first: #{PAGE_SIZE}, after: $cursor) {
          pageInfo { hasNextPage endCursor }
          edges { node { id title handle featuredImage { url } } }
        }
      }
    GRAPHQL

    def initialize(shop)
      @shop = shop.is_a?(Shop) ? shop : Shop.find_by!(shopify_domain: shop.to_s)
      @client = GraphQLClient.new(@shop)
    end

    # Returns { products: int, fitments_updated: int, errors: [String] }.
    def run
      report = { products: 0, fitments_updated: 0, errors: [] }
      cursor = nil

      MAX_PAGES.times do
        data = @client.query(QUERY, { "cursor" => cursor })
        edges = data.dig("products", "edges") || []
        page_info = data.dig("products", "pageInfo") || {}

        edges.each { |edge| apply(edge.fetch("node", {}), report) }
        report[:products] += edges.size

        break unless page_info["hasNextPage"] && page_info["endCursor"].present?

        cursor = page_info["endCursor"]
      end

      report
    rescue StandardError => e
      report[:errors] << "Query failed: #{e.class}: #{e.message}"
      report
    end

    private

    def apply(node, report)
      pid = node["id"]
      return if pid.blank?

      attrs = {}
      attrs[:product_title] = node["title"] if node["title"].present?
      attrs[:product_handle] = node["handle"] if node["handle"].present?
      image = node.dig("featuredImage", "url")
      attrs[:product_image] = image if image.present?
      return if attrs.empty?

      # Cache rows mirror Shopify data; skip callbacks like the webhooks do.
      # rubocop:disable-next Rails/SkipsModelValidations -- cached metadata
      report[:fitments_updated] += @shop.vehicle_product_fitments.where(product_id: pid).update_all(attrs)
    rescue StandardError => e
      report[:errors] << "#{pid}: #{e.message}"
    end
  end
end
