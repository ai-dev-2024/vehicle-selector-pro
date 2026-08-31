require "rails_helper"

RSpec.describe "Admin OE numbers", type: :request do
  let(:shop) { create(:shop) }

  before do
    allow(Rails.env).to receive(:local?).and_return(false)
    # Simulate an authenticated Shopify session (session repository is Shop).
    session_id = ShopifyApp::SessionRepository.store_shop_session(
      ShopifyAPI::Auth::Session.new(shop: shop.shopify_domain, access_token: shop.shopify_token)
    )
    allow_any_instance_of(Admin::BaseController).to receive(:current_shopify_session).and_return(
      ShopifyApp::SessionRepository.retrieve_shop_session(session_id)
    )
  end

  describe "GET /admin/oe_numbers" do
    it "lists the shop's OE numbers" do
      create(:oe_number, shop: shop, oe_number: "51372-TG7-A01")
      get admin_oe_numbers_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("51372-TG7-A01")
    end

    it "filters by search query" do
      create(:oe_number, shop: shop, oe_number: "ABC-123")
      create(:oe_number, shop: shop, oe_number: "XYZ-999")
      get admin_oe_numbers_path, params: { query: "abc" }
      expect(response.body).to include("ABC-123")
      expect(response.body).not_to include("XYZ-999")
    end
  end

  describe "POST /admin/oe_numbers" do
    it "creates an OE number and redirects" do
      expect do
        post admin_oe_numbers_path, params: { oe_number: { product_id: "gid://shopify/Product/1", oe_number: "51372-tg7" } }
      end.to change(shop.oe_numbers, :count).by(1)
      expect(response).to redirect_to(admin_oe_numbers_path)
      expect(shop.oe_numbers.last.oe_number).to eq("51372-TG7")
    end

    it "rejects a duplicate OE number for the same shop" do
      create(:oe_number, shop: shop, oe_number: "ABC-123")
      expect do
        post admin_oe_numbers_path, params: { oe_number: { product_id: "gid://shopify/Product/1", oe_number: "abc-123" } }
      end.not_to change(shop.oe_numbers, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /admin/oe_numbers/:id" do
    it "removes the OE number" do
      oe = create(:oe_number, shop: shop)
      expect do
        delete admin_oe_number_path(oe)
      end.to change(shop.oe_numbers, :count).by(-1)
      expect(response).to redirect_to(admin_oe_numbers_path)
    end
  end

  describe "POST /admin/oe_numbers/import" do
    it "imports rows from raw CSV, skipping duplicates" do
      create(:oe_number, shop: shop, oe_number: "EXISTS-1")
      csv = "product_id,oe_number\ngid://shopify/Product/1,NEW-1\ngid://shopify/Product/1,exists-1\ngid://shopify/Product/2,NEW-2\n"
      expect do
        post import_admin_oe_numbers_path, params: { csv_raw_text: csv }
      end.to change(shop.oe_numbers, :count).by(2)
      expect(response).to redirect_to(admin_oe_numbers_path)
    end
  end

  describe "GET /admin/oe_numbers/sample_template" do
    it "downloads a CSV template" do
      get sample_template_admin_oe_numbers_path
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to include("text/csv")
      expect(response.body).to include("product_id,oe_number")
    end
  end
end
