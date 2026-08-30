module Shopify
  class MetafieldDefinitionService
    NAMESPACE = "custom"
    KEY = "vehicle_fitment"

    CREATE_DEFINITION_MUTATION = <<~GRAPHQL
      mutation CreateMetafieldDefinition($definition: MetafieldDefinitionInput!) {
        metafieldDefinitionCreate(definition: $definition) {
          createdDefinition {
            id
            name
            namespace
            key
            type {
              name
            }
          }
          userErrors {
            field
            message
            code
          }
        }
      }
    GRAPHQL

    CHECK_DEFINITIONS_QUERY = <<~GRAPHQL
      query GetMetafieldDefinitions($ownerType: MetafieldOwnerType!, $namespace: String!, $key: String!) {
        metafieldDefinitions(first: 5, ownerType: $ownerType, namespace: $namespace, key: $key) {
          edges {
            node {
              id
              name
              namespace
              key
              type {
                name
              }
            }
          }
        }
      }
    GRAPHQL

    def self.ensure_definitions!(shop)
      new(shop).ensure_definition!
    end

    def initialize(shop)
      @shop = shop
      @client = GraphQLClient.new(shop)
    end

    def ensure_definition!
      # Check if definition already exists
      existing = find_definition
      return existing if existing.present?

      create_definition
    end

    private

    def find_definition
      response = @client.query(CHECK_DEFINITIONS_QUERY, {
                                 ownerType: "PRODUCT",
                                 namespace: NAMESPACE,
                                 key: KEY
                               })

      edges = response.dig("metafieldDefinitions", "edges") || []
      edges.first&.dig("node")
    rescue StandardError => e
      Rails.logger.warn("[MetafieldDefinitionService] Lookup failed: #{e.message}")
      nil
    end

    def create_definition
      variables = {
        definition: {
          name: "Vehicle Fitment Matrix",
          namespace: NAMESPACE,
          key: KEY,
          description: "Stores normalized vehicle fitment list and universal fit attributes for Vehicle Selector Pro",
          ownerType: "PRODUCT",
          type: "json",
          pin: true,
          access: {
            storefront: "PUBLIC_READ"
          }
        }
      }

      result = @client.mutate(CREATE_DEFINITION_MUTATION, variables)
      user_errors = result.dig("metafieldDefinitionCreate", "userErrors") || []

      if user_errors.any?
        # If already taken, that's fine
        if user_errors.any? { |e| e["code"] == "TAKEN" || e["message"].to_s.include?("already exists") }
          Rails.logger.info("[MetafieldDefinitionService] Definition already exists on #{@shop.shopify_domain}")
          return find_definition
        end
        raise GraphQLError, "Failed to create metafield definition: #{user_errors.map { |e| e['message'] }.join(', ')}"
      end

      result.dig("metafieldDefinitionCreate", "createdDefinition")
    end
  end
end
