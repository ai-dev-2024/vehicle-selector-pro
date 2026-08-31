require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Enable caching
  config.action_controller.perform_caching = true
  config.cache_store = :solid_cache_store

  # Active Storage / Mailer placeholders
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Allow sandbox / tunnel preview hosts (dev only)
  config.hosts << /.*\.sandbox\.novita\.ai/
  config.hosts << /.*\.e2b\.dev/
  config.hosts << /.*\.ngrok.*\.(app|io|dev)/
  config.hosts << /.*\.trycloudflare\.com/
end
