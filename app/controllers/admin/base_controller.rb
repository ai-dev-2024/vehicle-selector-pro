module Admin
  class BaseController < ApplicationController
    layout 'embedded_app'
    before_action :set_current_shop

    helper_method :current_shop

    protected

    def current_shop
      @current_shop
    end

    private

    def set_current_shop
      # In production, shopify_app gem sets session[:shopify_user_id] / shop_domain
      shop_domain = params[:shop] || session[:shop_domain] || ENV['SHOPIFY_STORE_DOMAIN']

      if shop_domain.present?
        @current_shop = Shop.find_by(shopify_domain: shop_domain)
      end

      # Fallback for local development or testing
      @current_shop ||= Shop.first

      unless @current_shop
        if Rails.env.development? || Rails.env.test?
          @current_shop = Shop.create!(
            shopify_domain: "apex-performance-parts.myshopify.com",
            shopify_token: "dev_token_placeholder",
            name: "Apex Performance Auto"
          )
        else
          redirect_to '/login'
        end
      end
    end
  end
end
