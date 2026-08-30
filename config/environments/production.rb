require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  # Ensure that assets are served in production if needed
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Cache configuration: Redis in production (Fly private Redis). The
  # SolidCache fallback was removed because it requires its own migration
  # (solid_cache_entries table) which this app does not have; without it the
  # branch crashed at runtime. Production always deploys with REDIS_URL set,
  # so fall back to a bounded memory store only as a last resort.
  config.cache_store = if ENV["REDIS_URL"].present?
                         [:redis_cache_store, {
                           url: ENV["REDIS_URL"],
                           connect_timeout: 10,
                           read_timeout: 0.2,
                           write_timeout: 0.2,
                           reconnect_attempts: 1,
                           error_handler: lambda { |_method:, _returning:, exception:|
                             Rails.logger.error("Redis Cache error: #{exception.message}")
                           }
                         }]
                       else
                         [:memory_store, { size: 128.megabytes }]
                       end

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info").to_sym
  config.log_tags = [:request_id]
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.active_record.dump_schema_after_migration = false
end
