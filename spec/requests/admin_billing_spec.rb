require "rails_helper"

RSpec.describe "Admin billing", type: :request do
  let(:shop) { create(:shop) }

  before do
    authenticate_admin!(shop)
    # The show/return actions reconcile billing_plan by querying Shopify's
    # active subscriptions; stub that so no real GraphQL call is made.
    service = instance_double(Shopify::BillingService)
    allow(Shopify::BillingService).to receive(:new).and_return(service)
    allow(service).to receive(:active_plan_key).and_return(nil)
  end

  describe "GET /admin/billing" do
    it "renders the plan cards" do
      get admin_billing_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Pro")
      expect(response.body).to include("Pro Plus")
    end

    it "reconciles billing_plan from Shopify's active subscriptions" do
      allow(Shopify::BillingService).to receive(:new).and_return(double(active_plan_key: "pro"))

      get admin_billing_path
      expect(shop.reload.billing_plan).to eq("pro")
      expect(shop.reload.on_paid_plan?).to be(true)
    end
  end

  describe "POST /admin/billing" do
    it "renders the embedded-safe breakout page pointing at Shopify's confirmation URL" do
      service = instance_double(Shopify::BillingService)
      allow(Shopify::BillingService).to receive(:new).and_return(service)
      allow(service).to receive(:create_subscription).and_return("https://checkout.example/confirm")

      post admin_billing_path, params: { plan: "pro" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("https://checkout.example/confirm")
      # The breakout page navigates the top window (the app is embedded in the
      # Shopify admin iframe; Shopify's billing page refuses to render in a frame).
      expect(response.body).to include("window.top.location.href")
    end

    it "passes the request origin as the returnUrl host" do
      service = instance_double(Shopify::BillingService)
      allow(Shopify::BillingService).to receive(:new).and_return(service)
      allow(service).to receive(:create_subscription).and_return(nil)

      # Pin the request origin so the assertion is deterministic across
      # environments, and clear any developer-local HOST override.
      old_host = ENV.fetch("HOST", nil)
      ENV.delete("HOST")
      begin
        host! "billing-test.example.com"
        post admin_billing_path, params: { plan: "pro" }
        expect(service).to have_received(:create_subscription)
          .with("pro", return_host: "http://billing-test.example.com")
      ensure
        ENV["HOST"] = old_host
      end
    end

    it "still redirects back with a notice when the shop is already subscribed" do
      service = instance_double(Shopify::BillingService)
      allow(Shopify::BillingService).to receive(:new).and_return(service)
      allow(service).to receive(:create_subscription).and_return(nil)

      post admin_billing_path, params: { plan: "pro" }
      expect(response).to redirect_to(admin_billing_path)
      expect(flash[:notice]).to be_present
    end

    it "rejects an unknown plan without calling Shopify" do
      service = instance_double(Shopify::BillingService)
      allow(Shopify::BillingService).to receive(:new).and_return(service)
      allow(service).to receive(:create_subscription)

      post admin_billing_path, params: { plan: "platinum" }
      expect(response).to redirect_to(admin_billing_path)
      expect(service).not_to have_received(:create_subscription)
    end
  end

  describe "GET /admin/billing/return" do
    it "marks the shop as paid when Shopify reports an active subscription" do
      allow(Shopify::BillingService).to receive(:new).and_return(double(active_plan_key: "plus"))

      get return_admin_billing_path
      expect(shop.reload.billing_plan).to eq("plus")
      expect(response).to redirect_to(admin_billing_path)
    end
  end

  describe "bulk import plan gating" do
    context "on the free (default) plan" do
      it "blocks an import that would exceed the limit and routes to billing" do
        create(:vehicle_product_fitment, shop: shop)
        shop.update!(billing_plan: BillingPlan::FREE)
        big_csv = "product_id,year,make,model\n#{"gid://shopify/Product/1,2024,Ford,F-150\n" * 600}"

        post admin_bulk_imports_path, params: { csv_raw_text: big_csv }
        expect(response).to redirect_to(admin_billing_path)
      end
    end

    context "on a paid plan" do
      it "allows an import under the raised limit" do
        shop.update!(billing_plan: BillingPlan::PRO, billing_expires_at: 30.days.from_now)
        csv = "product_id,year,make,model\ngid://shopify/Product/1,2024,Ford,F-150\ngid://shopify/Product/2,2023,GMC,Sierra\n"
        expect do
          post admin_bulk_imports_path, params: { csv_raw_text: csv }
        end.to change(shop.vehicle_product_fitments, :count)
        expect(response).not_to redirect_to(admin_billing_path)
      end
    end
  end
end
