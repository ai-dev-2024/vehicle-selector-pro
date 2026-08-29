module Admin
  class SyncController < BaseController
    def show
      @pending_count = current_shop.vehicle_product_fitments.pending_sync.count
      @synced_count = current_shop.vehicle_product_fitments.synced.count
      @total_products = current_shop.unique_products_count
      @sync_logs = current_shop.metafield_sync_logs.recent.limit(20)
    end

    def trigger_all
      log = current_shop.metafield_sync_logs.create!(
        sync_type: 'full',
        status: 'pending',
        total_products: current_shop.unique_products_count
      )

      Metafields::BatchSyncJob.perform_later(current_shop.id, nil, log.id)

      redirect_to admin_sync_path, notice: "Full shop metafield synchronization queued in background."
    end

    def trigger_product
      product_id = params[:product_id]
      if product_id.blank?
        return redirect_to admin_sync_path, alert: "Product ID is required."
      end

      Metafields::ProductMetafieldSyncJob.perform_later(current_shop.id, product_id)
      redirect_to admin_sync_path, notice: "Metafield sync queued for product #{product_id}."
    end

    def status
      latest_log = current_shop.metafield_sync_logs.recent.first
      render json: {
        pending_count: current_shop.vehicle_product_fitments.pending_sync.count,
        synced_count: current_shop.vehicle_product_fitments.synced.count,
        latest_log: latest_log ? {
          id: latest_log.id,
          status: latest_log.status,
          total: latest_log.total_products,
          synced: latest_log.synced_products,
          progress: latest_log.progress_percentage,
          error: latest_log.error_details
        } : nil
      }
    end
  end
end
