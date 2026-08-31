require "openssl"
require "active_support/security_utils"

class AppProxySignatureVerifier
  def self.valid?(query_params, secret = ShopifyApp.configuration.secret)
    new(query_params, secret).valid?
  end

  def initialize(query_params, secret)
    @params = query_params.respond_to?(:to_unsafe_h) ? query_params.to_unsafe_h : query_params.to_h
    @secret = secret.to_s
  end

  def valid?
    return false if @secret.blank?

    provided_signature = @params["signature"] || @params[:signature]
    return false if provided_signature.blank?

    calculated_signature = calculate_signature
    ActiveSupport::SecurityUtils.secure_compare(provided_signature.to_s, calculated_signature.to_s)
  end

  def calculate_signature
    # Step 1: Remove 'signature' and routing params if present
    filtered = @params.reject { |k, _| %w[signature action controller format].include?(k.to_s) }

    # Step 2: Sort parameters alphabetically by key and join as key=value
    sorted_pairs = filtered.sort_by { |k, _| k.to_s }.map do |k, v|
      value_str = v.is_a?(Array) ? v.join(",") : v.to_s
      "#{k}=#{value_str}"
    end

    # Step 3: Compute HMAC-SHA256 hex digest
    message = sorted_pairs.join
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, message)
  end
end
