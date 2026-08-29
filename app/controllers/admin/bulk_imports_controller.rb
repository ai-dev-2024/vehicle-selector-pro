module Admin
  class BulkImportsController < BaseController
    def index
      @recent_fitments_count = current_shop.vehicle_product_fitments.count
    end

    def create
      if params[:csv_file].blank? && params[:csv_raw_text].blank?
        return redirect_to admin_bulk_imports_path, alert: "Please choose a CSV file or paste CSV text."
      end

      csv_content = if params[:csv_file].present?
                      params[:csv_file].read
                    else
                      params[:csv_raw_text]
                    end

      importer = BulkFitmentImporter.new(current_shop, csv_content)
      results = importer.import!

      if results[:error_count].zero?
        redirect_to admin_product_fitments_path, notice: "Successfully imported #{results[:success_count]} vehicle fitments across #{results[:product_ids].size} products! Metafield background sync queued."
      else
        @results = results
        flash.now[:alert] = "Import completed with #{results[:error_count]} error(s). #{results[:success_count]} fitments imported."
        render :index, status: :unprocessable_entity
      end
    end

    def sample_template
      csv_data = CSV.generate(headers: true) do |csv|
        csv << %w[product_id product_handle product_title sku year make model trim engine universal notes position]
        csv << ["gid://shopify/Product/8192019283001", "cold-air-intake-f150", "Stage 2 Cold Air Intake", "CAI-F150", "2024", "Ford", "F-150", "Lariat", "3.5L EcoBoost V6", "false", "Fits twin-turbo models only", "Engine Bay"]
        csv << ["gid://shopify/Product/8192019283002", "heavy-duty-brake-kit", "Severe Duty Brake Rotor Kit", "BRK-HD-01", "2024", "Chevrolet", "Silverado 1500", "LTZ", "6.2L EcoTec3 V8", "false", "Front axle 6-lug", "Front Axle"]
        csv << ["gid://shopify/Product/8192019283006", "universal-led-fog-lights", "High-Power Amber LED Fog Pods", "LED-FOG-UNIV", "", "", "", "", "", "true", "Universal mounting bracket included", "Auxiliary"]
      end

      send_data csv_data, filename: "vehicle_selector_pro_fitment_template.csv", type: "text/csv"
    end
  end
end
