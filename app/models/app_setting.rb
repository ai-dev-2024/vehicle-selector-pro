class AppSetting < ApplicationRecord
  include ShopScoped

  validates :widget_title, presence: true
  validates :layout_style, inclusion: { in: %w[horizontal vertical popup compact] }
  validates :max_garage_vehicles,
            numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  def to_theme_config
    {
      widget_title: widget_title,
      widget_subtitle: widget_subtitle,
      layout_style: layout_style,
      primary_color: primary_color,
      button_label: button_label,
      reset_label: reset_label,
      enable_trim: enable_trim,
      enable_engine: enable_engine,
      enable_garage: enable_garage,
      max_garage_vehicles: max_garage_vehicles,
      auto_filter_collections: auto_filter_collections,
      filter_query_param: filter_query_param,
      fitment_guarantee_text: fitment_guarantee_text,
      show_badge_on_product_page: show_badge_on_product_page
    }
  end
end
