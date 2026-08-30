module Admin
  class SettingsController < BaseController
    def show
      @settings = current_shop.settings
    end

    def update
      @settings = current_shop.settings
      if @settings.update(settings_params)
        redirect_to admin_settings_path, notice: t("admin.settings.saved")
      else
        flash.now[:alert] = @settings.errors.full_messages.join(", ")
        render :show, status: :unprocessable_content
      end
    end

    private

    def settings_params
      params.require(:app_setting).permit(
        :widget_title, :widget_subtitle, :layout_style, :primary_color,
        :button_label, :reset_label, :enable_trim, :enable_engine,
        :enable_garage, :max_garage_vehicles, :auto_filter_collections,
        :fitment_guarantee_text, :show_badge_on_product_page
      )
    end
  end
end
