module Admin
  class DashboardController < BaseController
    def index
      @total_fitments = current_shop.vehicle_product_fitments.count
      @unique_products = current_shop.unique_products_count
      @total_vehicles = current_shop.vehicles.count
      @universal_products = current_shop.vehicle_product_fitments.universal.count
      @pending_sync_count = current_shop.vehicle_product_fitments.pending_sync.count
      @synced_count = current_shop.vehicle_product_fitments.synced.count
      @coverage_pct = ((@synced_count.to_f / [current_shop.vehicle_product_fitments.count, 1].max) * 100).round(1)

      @recent_fitments = current_shop.vehicle_product_fitments
                                     .includes(:vehicle)
                                     .order(created_at: :desc)
                                     .limit(10)

      @recent_sync_logs = current_shop.metafield_sync_logs.recent.limit(5)
    end
  end
end
