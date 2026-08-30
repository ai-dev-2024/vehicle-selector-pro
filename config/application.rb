require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"

Bundler.require(*Rails.groups)

module VehicleSelectorPro
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # app/services and app/jobs are autoloaded and eager-loaded by Rails
    # convention (all app/* subdirectories); no manual registration needed.

    # Configuration for the application, engines, and railties goes here.
    config.active_job.queue_adapter = :sidekiq

    # Cache store: SolidCache (Postgres) in production, memory for dev/test
    config.cache_store = if ENV["REDIS_URL"].present?
                           [:redis_cache_store, { url: ENV["REDIS_URL"], reconnect_attempts: 1 }]
                         else
                           [:memory_store, { size: 64.megabytes }]
                         end

    # Active Record encryption (Shopify tokens are encrypted at rest).
    # Production must supply these via environment (Fly secrets); dev/test
    # fall back to stable local-only keys so encrypted data stays readable.
    if Rails.env.local?
      config.active_record.encryption.primary_key = ENV["ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY"] || "local_dev_primary_key"
      config.active_record.encryption.deterministic_key = ENV["ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY"] || "local_dev_deterministic_key"
      config.active_record.encryption.key_derivation_salt =
        ENV["ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT"] || "local_dev_key_derivation_salt"
    else
      config.active_record.encryption.primary_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY") do
        Rails.application.credentials.dig(:active_record_encryption, :primary_key)
      end
      config.active_record.encryption.deterministic_key = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY") do
        Rails.application.credentials.dig(:active_record_encryption, :deterministic_key)
      end
      config.active_record.encryption.key_derivation_salt = ENV.fetch("ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT") do
        Rails.application.credentials.dig(:active_record_encryption, :key_derivation_salt)
      end
    end

    # Shopify embedded app: allow framing by Shopify admin
    config.action_dispatch.default_headers.delete("X-Frame-Options")
    config.action_dispatch.default_headers["X-Frame-Options"] = ""
    config.content_security_policy do |policy|
      policy.frame_ancestors :self, "https://*.myshopify.com", "https://admin.shopify.com"
    end
  end
end
