module Shopify
  class MetafieldSyncService
    # Merchant-visible metafield pinned on the store:
    #   custom.vehicle_fitment  type = "json"  (storefront PUBLIC_READ)
    # Definition is ensured by MetafieldDefinitionService; we always send
    # namespace + type explicitly so metafieldsSet works even before the
    # definition exists.
    NAMESPACE = "custom".freeze
    KEY = "vehicle_fitment".freeze
    TYPE = "json".freeze
    BATCH_SIZE = 25

    METAFIELDS_SET_MUTATION = <<~GRAPHQL.freeze
      mutation MetafieldsSet($metafields: [MetafieldsSetInput!]!) {
        metafieldsSet(metafields: $metafields) {
          metafields {
            id
            namespace
            key
            value
          }
          userErrors {
            field
            message
            code
          }
        }
      }
    GRAPHQL

    def self.sync_product(shop, product_id)
      new(shop).sync_products([product_id])
    end

    def self.sync_all_products(shop, log: nil)
      new(shop).sync_all(log: log)
    end

    def initialize(shop)
      @shop = shop.is_a?(Shop) ? shop : Shop.find_by!(shopify_domain: shop.to_s)
      @client = GraphQLClient.new(@shop)
    end

    def sync_products(product_ids)
      return { success: true, count: 0 } if product_ids.blank?

      metafields_payload = []
      product_ids.each do |pid|
        payload = build_metafield_payload_for_product(pid)
        metafields_payload << payload if payload.present?
      end

      # Slice into batches of 25 for Shopify GraphQL limitations
      metafields_payload.each_slice(BATCH_SIZE) do |batch|
        execute_batch(batch)
      end

      # Update local records
      # rubocop:disable-next Rails/SkipsModelValidations -- sync status bookkeeping; must skip callbacks
      @shop.vehicle_product_fitments.where(product_id: product_ids).update_all(
        synced_to_metafield: true,
        last_synced_at: Time.current
      )

      { success: true, count: product_ids.size }
    rescue StandardError => e
      Rails.logger.error("[MetafieldSyncService] Failed syncing products #{product_ids}: #{e.message}")
      raise
    end

    def sync_all(log: nil)
      product_ids = @shop.vehicle_product_fitments.distinct.pluck(:product_id)
      log&.mark_in_progress!(product_ids.size)

      synced = 0
      product_ids.each_slice(BATCH_SIZE) do |batch_ids|
        sync_products(batch_ids)
        synced += batch_ids.size
      end

      log&.mark_completed!(synced)
      { success: true, total_synced: synced }
    rescue StandardError => e
      log&.mark_failed!(e)
      raise
    end

    private

    # rubocop:disable-next Metrics/MethodLength -- payload assembly mirrors the Shopify JSON schema section by section
    def build_metafield_payload_for_product(product_id)
      fitments = @shop.vehicle_product_fitments.where(product_id: product_id).includes(:vehicle)
      return nil if fitments.empty?

      universal = fitments.any?(&:universal_fit?)

      fitment_list = fitments.map do |f|
        if f.universal_fit?
          {
            universal: true,
            notes: f.fitment_notes,
            position: f.position
          }
        elsif f.vehicle.present?
          {
            year: f.vehicle.year,
            make: f.vehicle.make,
            model: f.vehicle.model,
            trim: f.vehicle.trim,
            engine: f.vehicle.engine,
            drivetrain: f.vehicle.drivetrain,
            body_style: f.vehicle.body_style,
            notes: f.fitment_notes,
            position: f.position,
            fitment_type: f.fitment_type
          }
        end
      end.compact

      # Build compact searchable tokens for fast Liquid / Storefront filtering
      ymm_keys = fitments.map do |f|
        next "universal" if f.universal_fit?
        next unless f.vehicle

        "#{f.vehicle.year}|#{f.vehicle.make.downcase}|#{f.vehicle.model.downcase}"
      end.compact.uniq

      metafield_value = {
        universal: universal,
        total_vehicles: universal ? "all" : fitments.count,
        fitments: fitment_list,
        ymm_keys: ymm_keys,
        last_updated: Time.current.iso8601
      }.to_json

      # Format GID if needed
      owner_gid = product_id.to_s.start_with?("gid://") ? product_id : "gid://shopify/Product/#{product_id}"

      {
        ownerId: owner_gid,
        namespace: NAMESPACE,
        key: KEY,
        type: TYPE,
        value: metafield_value
      }
    end

    def execute_batch(batch)
      result = @client.mutate(METAFIELDS_SET_MUTATION, { metafields: batch })
      user_errors = result.dig("metafieldsSet", "userErrors") || []

      if user_errors.any?
        Rails.logger.error("[MetafieldSyncService] Metafield batch error: #{user_errors.inspect}")
        raise GraphQLError, "Failed to set metafields: #{user_errors.pluck('message').join('; ')}"
      end

      result.dig("metafieldsSet", "metafields")
    end
  end
end
