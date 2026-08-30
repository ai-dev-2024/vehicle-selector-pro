module Admin
  class BaseController < ApplicationController
    # Session-based auth, NOT EnsureInstalled: EnsureInstalled only proves the
    # app is installed on the shop named in params[:shop] — any visitor could
    # pass ?shop=<domain> and reach every admin action. EnsureHasSession (via
    # LoginProtection) requires a verified OAuth/JWT session for that shop, so
    # the two concerns must never be mixed (the gem raises if they are).
    include ShopifyApp::EnsureHasSession

    layout "embedded_app"
    before_action :set_current_shop

    helper_method :current_shop

    protected

    attr_reader :current_shop

    private

    def set_current_shop
      # Derive the shop ONLY from the verified session — never from params,
      # headers or ENV, which a caller controls.
      domain = current_shopify_session&.shop&.to_s
      @current_shop = domain && Shop.active.find_by(shopify_domain: domain)

      return if @current_shop

      redirect_to "/login" and return unless Rails.env.local?

      # Dev/test convenience: use first shop or seed a demo shop
      # rubocop:disable Naming/MemoizedInstanceVariableName -- @current_shop is the conventional name read by every action
      @current_shop = Shop.active.first || Shop.first
      @current_shop ||= Shop.create!(
        shopify_domain: "apex-performance-parts.myshopify.com",
        shopify_token: "dev_token_placeholder",
        name: "Apex Performance Auto"
      )
      # rubocop:enable Naming/MemoizedInstanceVariableName
    end
  end
end
