require "rails_helper"

RSpec.describe AppProxySignatureVerifier do
  let(:secret) { "my_super_secret_shopify_key_12345" }

  def signed_params(params, signing_secret = secret)
    filtered = params.reject { |k, _| %w[signature action controller format].include?(k.to_s) }
    message = filtered.sort_by { |k, _| k.to_s }.map { |k, v| "#{k}=#{v}" }.join
    params.merge("signature" => OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), signing_secret, message))
  end

  describe ".valid?" do
    it "accepts only correctly signed requests" do
      # [params, verifier secret, expected]
      cases = [
        [signed_params("shop" => "apex-parts.myshopify.com", "timestamp" => "1724900000", "year" => "2024", "make" => "Ford"),
         secret, true],
        [signed_params("shop" => "apex-parts.myshopify.com").merge("controller" => "app_proxy/vehicle_filters", "action" => "years"),
         secret, true]
      ]

      cases.each do |params, verifier_secret, expected|
        expect(described_class.valid?(params, verifier_secret)).to be(expected)
      end
    end

    it "rejects tampered, wrong-secret, unsigned and blank-secret requests" do
      cases = [
        [signed_params("shop" => "apex-parts.myshopify.com", "year" => "2024").merge("year" => "2023"), secret],
        [signed_params({ "shop" => "apex-parts.myshopify.com" }, "other_secret"), secret],
        [{ "shop" => "apex-parts.myshopify.com", "year" => "2024" }, secret],
        [signed_params("shop" => "apex-parts.myshopify.com"), ""]
      ]

      cases.each do |params, verifier_secret|
        expect(described_class.valid?(params, verifier_secret)).to be(false)
      end
    end
  end
end
