require_relative "../spec_helper"

class AppProxySignatureVerifierTest < Minitest::Test
  def setup
    @secret = "my_super_secret_shopify_key_12345"
  end

  def test_valid_signature_calculation_and_verification
    params = {
      "shop" => "apex-parts.myshopify.com",
      "path_prefix" => "/apps/vehicle-selector",
      "timestamp" => "1724900000",
      "year" => "2024",
      "make" => "Ford"
    }

    # Sorted order: make=Fordpath_prefix=/apps/vehicle-selectorshop=apex-parts.myshopify.comtimestamp=1724900000year=2024
    expected_message = "make=Fordpath_prefix=/apps/vehicle-selectorshop=apex-parts.myshopify.comtimestamp=1724900000year=2024"
    expected_signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, expected_message)

    params_with_signature = params.merge("signature" => expected_signature)

    verifier = AppProxySignatureVerifier.new(params_with_signature, @secret)
    assert verifier.valid?, "Expected signature to be valid"
    assert_equal expected_signature, verifier.calculate_signature
  end

  def test_tampered_parameter_fails_verification
    params = {
      "shop" => "apex-parts.myshopify.com",
      "year" => "2024",
      "make" => "Ford"
    }
    valid_sig = AppProxySignatureVerifier.new(params, @secret).calculate_signature

    # Tamper with year parameter
    tampered_params = params.merge("year" => "2023", "signature" => valid_sig)
    refute AppProxySignatureVerifier.valid?(tampered_params, @secret), "Tampered parameter must fail verification"
  end

  def test_missing_signature_fails
    params = { "shop" => "apex-parts.myshopify.com", "year" => "2024" }
    refute AppProxySignatureVerifier.valid?(params, @secret), "Missing signature must fail verification"
  end

  def test_empty_secret_fails
    params = { "shop" => "apex-parts.myshopify.com", "signature" => "anything" }
    refute AppProxySignatureVerifier.valid?(params, ""), "Empty secret must fail verification"
  end
end
