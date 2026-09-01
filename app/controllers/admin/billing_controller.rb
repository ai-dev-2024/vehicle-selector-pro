module Admin
  # Merchant-facing plan page. Renders the tier cards, lets a merchant start a
  # Shopify-native checkout for a plan (redirected to Shopify's confirmation
  # URL), and reconciles the shop's billing_plan from the active subscriptions
  # after they return from checkout.
  class BillingController < BaseController
    # GET /admin/billing
    def show
      refresh_plan_from_shopify

      @plans = BillingPlan.all
      @current_plan = current_shop.billing_plan_key
      @current_plan_obj = BillingPlan.find(@current_plan)
    end

    # POST /admin/billing/start
    def create
      plan_key = params[:plan].to_s.presence
      return redirect_to admin_billing_path, alert: t("admin.billing.invalid_plan") unless BillingPlan.find(plan_key)

      confirmation_url = Shopify::BillingService.new(current_shop)
                                                .create_subscription(plan_key, return_host: billing_host)
      return redirect_to admin_billing_path, notice: t("admin.billing.already_subscribed") if confirmation_url.blank?

      # The admin runs inside the Shopify admin iframe. Shopify's billing
      # confirmation page refuses to render in a frame (frame-ancestors), so a
      # plain redirect would leave the iframe unchanged — "the button does
      # nothing". Instead, render a tiny page that navigates the TOP window to
      # the confirmation URL (breaking out of the iframe), with a manual link
      # as a fallback if top-navigation is blocked.
      render :redirect_top, locals: { url: confirmation_url }, layout: false
    rescue Shopify::GraphQLError => e
      redirect_to admin_billing_path, alert: t("admin.billing.error", message: e.message)
    end

    # GET /admin/billing/return — Shopify sends the merchant back here after
    # the checkout dialog. Reconcile billing_plan and tell them the result.
    def return
      refreshed = refresh_plan_from_shopify

      if refreshed[:active]
        redirect_to admin_billing_path, notice: t("admin.billing.activated", plan: refreshed[:plan_name])
      else
        redirect_to admin_billing_path, alert: t("admin.billing.not_activated")
      end
    rescue Shopify::GraphQLError => e
      redirect_to admin_billing_path, alert: t("admin.billing.error", message: e.message)
    end

    private

    def billing_host
      # The returnUrl Shopify sends the merchant back to after checkout must be
      # this app's real public origin. request.base_url is correct everywhere
      # (https://vehicle-selector-pro.fly.dev on Fly, localhost:3000 in dev);
      # ENV["HOST"] stays as an override for proxied setups where the request
      # host doesn't match the public app URL.
      ENV["HOST"].presence || request.base_url.presence || "http://localhost:3000"
    end

    # Queries Shopify for active subscriptions and syncs shops.billing_plan +
    # billing_expires_at. Returns { active:, plan_name: }.
    def refresh_plan_from_shopify
      key = Shopify::BillingService.new(current_shop).active_plan_key
      plan = key && BillingPlan.find(key)

      current_shop.update!(
        billing_plan: plan ? plan.key : BillingPlan::FREE,
        billing_activated_at: plan ? Time.current : nil,
        billing_expires_at: plan ? 30.days.from_now : nil
      )

      { active: !plan.nil?, plan_name: plan&.name }
    end
  end
end
