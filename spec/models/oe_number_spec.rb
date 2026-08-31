require "rails_helper"

RSpec.describe OeNumber, type: :model do
  let(:shop) { create(:shop) }

  describe "normalization" do
    it "upcases and strips OE numbers before saving" do
      oe = create(:oe_number, shop: shop, oe_number: " 51372-tg7-a01 ")
      expect(oe.reload.oe_number).to eq("51372-TG7-A01")
    end

    it "enforces uniqueness per shop case-insensitively" do
      create(:oe_number, shop: shop, oe_number: "ABC-123")
      duplicate = build(:oe_number, shop: shop, oe_number: "abc-123")
      expect(duplicate).not_to be_valid
    end
  end

  describe ".product_ids_for" do
    it "returns matching product ids for a partial OE search" do
      create(:oe_number, shop: shop, product_id: "gid://shopify/Product/1", oe_number: "51372-TG7-A01")
      create(:oe_number, shop: shop, product_id: "gid://shopify/Product/2", oe_number: "1806-C41-A00")

      expect(OeNumber.product_ids_for(shop, "51372-tg7")).to contain_exactly("gid://shopify/Product/1")
    end

    it "returns [] for a blank term or no matches" do
      expect(OeNumber.product_ids_for(shop, "")).to eq([])
      expect(OeNumber.product_ids_for(shop, "NOPE-999")).to eq([])
    end
  end
end
