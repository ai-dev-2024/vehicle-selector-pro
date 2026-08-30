require "rails_helper"

RSpec.describe AppProxySignatureVerifier do
  let(:secret) { "my_super_secret_shopify_key_12345" }

  def signed_params(params, signing_secret = secret)
    filtered = params.reject { |k, _| %w[signature action controller format].include?(k.to_s) }
    message = filtered.sort_by { |k, _| k.to_s }.map { |k, v| "#{k}=#{v}" }.join
    params.merge("signature" => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), signing_secret, message))
  end

  it "validates a correctly signed request" do
    params = signed_params("shop" => "apex-parts.myshopify.com", "timestamp" => "1724900000",
                           "year" => "2024", "make" => "Ford")
    expect(described_class.valid?(params, secret)).to be(true)
  end

  it "rejects a tampered value" do
    params = signed_params("shop" => "apex-parts.myshopify.com", "year" => "2024")
    params["year"] = "2023"
    expect(described_class.valid?(params, secret)).to be(false)
  end

  it "rejects a wrong secret" do
    params = signed_params({ "shop" => "apex-parts.myshopify.com" }, "other_secret")
    expect(described_class.valid?(params, secret)).to be(false)
  end

  it "rejects a missing signature" do
    expect(described_class.valid?({ "shop" => "apex-parts.myshopify.com", "year" => "2024" }, secret)).to be(false)
  end

  it "rejects when the app secret is blank" do
    params = signed_params("shop" => "apex-parts.myshopify.com")
    expect(described_class.valid?(params, "")).to be(false)
  end

  it "ignores routing params when calculating the signature" do
    signed = signed_params("shop" => "apex-parts.myshopify.com")
    signed["controller"] = "app_proxy/vehicle_filters"
    signed["action"] = "years"
    expect(described_class.valid?(signed, secret)).to be(true)
  end
end
