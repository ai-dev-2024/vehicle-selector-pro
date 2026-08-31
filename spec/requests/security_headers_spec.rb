require "rails_helper"

RSpec.describe "Security headers", type: :request do
  it "sends CSP, nosniff and frame-ancestors on controller responses" do
    allow(Rails.env).to receive(:local?).and_return(false)
    get "/health/deep"

    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
    expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("frame-ancestors https://*.myshopify.com")
    expect(csp).to include("default-src 'self'")
  end

  it "does not expose the Shopify token in any response header" do
    allow(Rails.env).to receive(:local?).and_return(false)
    get "/health/deep"
    expect(response.headers.keys.join(" ")).not_to match(/token|secret/i)
  end
end

RSpec.describe "Production fallback guards", type: :request do
  # The admin dev convenience path creates a demo shop with a placeholder token
  # when no shop exists — that must be impossible outside local/dev/test envs,
  # otherwise a misconfigured deploy would silently create a bogus merchant row.
  it "redirects to /login instead of seeding a placeholder shop outside local env" do
    allow(Rails.env).to receive(:local?).and_return(false)

    # No current session (simulating a real visitor hitting the admin router).
    get "/admin/dashboard"
    expect(response).to redirect_to("/login").or have_http_status(:redirect)
    expect(Shop.where(shopify_token: "dev_token_placeholder").count).to eq(0)
  end
end
