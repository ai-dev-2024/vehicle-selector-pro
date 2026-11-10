require "rails_helper"

RSpec.describe "Admin bulk imports", type: :request do
  let(:shop) { create(:shop) }

  before { authenticate_admin!(shop) }

  # These used to redirect with "Successfully imported 0 vehicle fitments".
  it "reports a CSV with no usable columns as a failure, not a successful import" do
    post admin_bulk_imports_path, params: { csv_raw_text: "a,b\n1,2\n" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("CSV must contain at least one of")
  end

  it "reports a malformed CSV as a failure" do
    post admin_bulk_imports_path, params: { csv_raw_text: "product_id,year,make,model\n\"1001,2024,Ford,F-150\n" }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Malformed CSV")
  end

  it "imports a valid CSV and redirects to the fitment list" do
    post admin_bulk_imports_path, params: { csv_raw_text: "product_id,year,make,model\n1001,2024,Ford,F-150\n" }

    expect(response).to redirect_to(admin_product_fitments_path)
    expect(shop.vehicle_product_fitments.count).to eq(1)
  end
end
