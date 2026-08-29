require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module VehicleSelectorPro
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    config.autoload_lib(ignore: %w[assets tasks])

    # Auto-load services and workers
    config.autoload_paths << Rails.root.join('app/services')
    config.autoload_paths << Rails.root.join('app/jobs')

    # Configuration for the application, engines, and railties goes here.
    config.active_job.queue_adapter = :sidekiq

    # Cache store: SolidCache (Postgres) in production, memory for dev/test
    if ENV['REDIS_URL'].present?
      config.cache_store = :redis_cache_store, { url: ENV['REDIS_URL'], reconnect_attempts: 1 }
    else
      config.cache_store = :memory_store, { size: 64.megabytes }
    end

    # Shopify embedded app: allow framing by Shopify admin
    config.action_dispatch.default_headers.delete('X-Frame-Options')
    config.action_dispatch.default_headers['X-Frame-Options'] = ''
    config.content_security_policy do |policy|
      policy.frame_ancestors :self, "https://*.myshopify.com", "https://admin.shopify.com"
    end
  end
end
