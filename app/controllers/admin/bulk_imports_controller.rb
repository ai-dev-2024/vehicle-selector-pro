module Admin
  class BulkImportsController < BaseController
    def index
      @recent_fitments_count = current_shop.vehicle_product_fitments.count
    end

    def create
      if params[:csv_file].blank? && params[:csv_raw_text].blank?
        return redirect_to admin_bulk_imports_path, alert: t("admin.bulk_imports.choose_file_or_paste")
      end

      csv_content = if params[:csv_file].present?
                      params[:csv_file].read
                    else
                      params[:csv_raw_text]
                    end
      # Gate bulk imports on the shop's plan ceiling. A paid tier raises the
      # limit; the free tier is capped so the import is rejected upfront rather
      # than partially applied.
      if over_plan_limit?(current_shop, csv_content)
        limit = current_shop.planned_fitment_limit
        return redirect_to admin_billing_path,
                           alert: t("admin.bulk_imports.plan_limit",
                                    current: current_shop.vehicle_product_fitments.count, limit: limit)
      end

      importer = BulkFitmentImporter.new(current_shop, csv_content)
      results = importer.import!

      if results[:error_count].zero?
        redirect_to admin_product_fitments_path,
                    notice: t("admin.bulk_imports.import_success",
                              count: results[:success_count], products: results[:product_ids].size)
      else
        @results = results
        flash.now[:alert] =
          t("admin.bulk_imports.import_partial", error_count: results[:error_count], count: results[:success_count])
        render :index, status: :unprocessable_content
      end
    end

    def sample_template
      csv_data = CSV.generate(headers: true) do |csv|
        csv << %w[product_id product_handle product_title sku year make model trim engine universal notes position]
        csv << ["gid://shopify/Product/8192019283001", "cold-air-intake-f150", "Stage 2 Cold Air Intake", "CAI-F150",
                "2024", "Ford", "F-150", "Lariat", "3.5L EcoBoost V6", "false", "Fits twin-turbo models only", "Engine Bay"]
        csv << ["gid://shopify/Product/8192019283002", "heavy-duty-brake-kit", "Severe Duty Brake Rotor Kit",
                "BRK-HD-01", "2024", "Chevrolet", "Silverado 1500", "LTZ", "6.2L EcoTec3 V8", "false", "Front axle 6-lug", "Front Axle"]
        csv << ["gid://shopify/Product/8192019283006", "universal-led-fog-lights", "High-Power Amber LED Fog Pods",
                "LED-FOG-UNIV", "", "", "", "", "", "true", "Universal mounting bracket included", "Auxiliary"]
      end

      send_data csv_data, filename: "vehicle_selector_pro_fitment_template.csv", type: "text/csv"
    end

    private

    # True when adding every row in the CSV would push the shop past its plan
    # ceiling. The check is conservative (counts all lines) and rejects the
    # whole import upfront rather than partially applying it.
    def over_plan_limit?(shop, csv_content)
      import_size = csv_content.lines.count - 1
      shop.vehicle_product_fitments.count + import_size > shop.planned_fitment_limit
    end
  end
end
