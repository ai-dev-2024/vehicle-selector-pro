# Security headers applied to every response. The Shopify embedded admin runs
# inside the merchant's admin iframe, so frame-ancestors must allow
# *.myshopify.com and shopify.com while blocking everything else; the
# storefront preview (served from the app itself) is allowed as well.
module SecurityHeaders
  extend ActiveSupport::Concern

  included do
    after_action :set_security_headers
  end

  private

  def set_security_headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "SAMEORIGIN"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "camera=(), microphone=(), geolocation=()"

    # CSP with frame-ancestors allowing the Shopify admin + app proxy domains.
    # Script/style sources are intentionally permissive for the Polaris CDN,
    # Google Fonts and inline styles used by the embedded admin; tighten as the
    # asset pipeline grows.
    csp = [
      "default-src 'self'",
      "frame-ancestors https://*.myshopify.com https://*.shopify.com https://admin.shopify.com http://localhost:* https://localhost:*",
      "connect-src 'self' https://*.myshopify.com https://admin.shopify.com https://unpkg.com",
      "img-src 'self' data: blob: https:",
      "font-src 'self' https://fonts.gstatic.com data:",
      "style-src 'self' 'unsafe-inline' https://unpkg.com https://fonts.googleapis.com",
      "script-src 'self' 'unsafe-inline' https://unpkg.com",
      "base-uri 'self'",
      "form-action 'self'"
    ]
    response.headers["Content-Security-Policy"] = csp.join("; ")
  end
end
