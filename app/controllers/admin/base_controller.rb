module Admin
  class BaseController < ApplicationController
    include ShopifyApp::EnsureInstalled

    layout "embedded_app"
    before_action :set_current_shop

    helper_method :current_shop

    protected

    attr_reader :current_shop

    private

    def set_current_shop
      # ShopifyApp gem sets session via JWT/session; fallback to params for App Bridge fetches
      shop_domain = params[:shop] || session[:shopify_domain] || session[:shop_domain] || request.headers["X-Shopify-Shop-Domain"] || ENV.fetch(
        "SHOPIFY_STORE_DOMAIN", nil
      )

      @current_shop = Shop.active.find_by(shopify_domain: shop_domain) if shop_domain.present?

      return if @current_shop

      if Rails.env.local?
        # Dev/test convenience: use first shop or seed a demo shop
        @current_shop = Shop.active.first || Shop.first
        @current_shop ||= Shop.create!(
          shopify_domain: "apex-performance-parts.myshopify.com",
          shopify_token: "dev_token_placeholder",
          name: "Apex Performance Auto"
        )
      else
        # In production, enforce Shopify authentication
        redirect_to "/login?shop=#{shop_domain}" and return if shop_domain.present?

        redirect_to "/login" and return
      end
    end
  end
end
