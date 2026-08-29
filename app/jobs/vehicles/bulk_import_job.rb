module Vehicles
  class BulkImportJob < ApplicationJob
    queue_as :default

    def perform(shop_id, csv_content)
      shop = Shop.find_by(id: shop_id)
      return unless shop&.active?

      importer = BulkFitmentImporter.new(shop, csv_content)
      results = importer.import!

      Rails.logger.info("[BulkImportJob] Finished import for #{shop.shopify_domain}: #{results[:success_count]} success, #{results[:error_count]} errors")
      results
    rescue StandardError => e
      Rails.logger.error("[BulkImportJob] Failed: #{e.message}")
      raise e
    end
  end
end
