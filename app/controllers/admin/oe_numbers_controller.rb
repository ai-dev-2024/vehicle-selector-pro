module Admin
  # Merchant-facing management of Original Equipment (OE) part numbers. Lets a
  # merchant cross-reference their products against factory part numbers so
  # shoppers can search by the OE number printed on the part they already own.
  class OeNumbersController < BaseController
    def index
      @oe_numbers = current_shop.oe_numbers.includes(:shop)

      if params[:query].present?
        q = "%#{params[:query].strip.upcase}%"
        @oe_numbers = @oe_numbers.where("oe_number LIKE :q OR UPPER(product_id) LIKE :q", q: q)
      end

      @page = (params[:page] || 1).to_i
      @per_page = 25
      @total_count = @oe_numbers.count
      @oe_numbers = @oe_numbers.order(created_at: :desc).offset((@page - 1) * @per_page).limit(@per_page)
    end

    def create
      oe = current_shop.oe_numbers.new(oe_number_params)

      if oe.save
        redirect_to admin_oe_numbers_path,
                    notice: t("admin.oe_numbers.added", oe: oe.oe_number, product: oe.product_id)
      else
        flash.now[:alert] = oe.errors.full_messages.join(", ")
        index
        render :index, status: :unprocessable_content
      end
    end

    def destroy
      oe = current_shop.oe_numbers.find_by(id: params[:id])
      if oe
        oe.destroy
        redirect_to admin_oe_numbers_path, notice: t("admin.oe_numbers.removed", oe: oe.oe_number)
      else
        redirect_to admin_oe_numbers_path, alert: t("admin.oe_numbers.not_found")
      end
    end

    # CSV import: columns "product_id,oe_number" (header optional). One row per
    # OE number; rows already present are skipped, invalid rows are reported.
    def import
      if params[:csv_file].blank? && params[:csv_raw_text].blank?
        return redirect_to admin_oe_numbers_path, alert: t("admin.oe_numbers.choose_file_or_paste")
      end

      csv_content = params[:csv_file].present? ? params[:csv_file].read : params[:csv_raw_text]
      added = 0
      skipped = 0
      errors = []

      CSV.parse(csv_content, headers: true) do |row|
        product_id = row["product_id"].to_s.strip
        oe_number = row["oe_number"].to_s.strip
        next if product_id.blank? || oe_number.blank?

        record = current_shop.oe_numbers.new(product_id: product_id, oe_number: oe_number)
        if record.save
          added += 1
        elsif record.errors.added?(:oe_number, :taken)
          skipped += 1
        else
          errors << "#{oe_number}: #{record.errors.full_messages.join(', ')}"
        end
      end

      if errors.any?
        redirect_to admin_oe_numbers_path,
                    alert: t("admin.oe_numbers.import_partial", added: added, skipped: skipped, errors: errors.first(5).join("; "))
      else
        redirect_to admin_oe_numbers_path,
                    notice: t("admin.oe_numbers.import_success", added: added, skipped: skipped)
      end
    end

    def sample_template
      csv_data = CSV.generate(headers: true) do |csv|
        csv << %w[product_id oe_number]
        csv << ["gid://shopify/Product/8192019283001", "51372-TG7-A01"]
        csv << ["gid://shopify/Product/8192019283002", "1806-C41-A00"]
        csv << ["gid://shopify/Product/8192019283006", "H11-9005-UNIV"]
      end
      send_data csv_data, filename: "oe_numbers_template.csv", type: "text/csv"
    end

    private

    def oe_number_params
      params.require(:oe_number).permit(:product_id, :oe_number)
    end
  end
end
