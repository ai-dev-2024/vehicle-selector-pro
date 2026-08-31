redis_url = ENV.fetch("REDIS_URL", "redis://localhost:6379/1")

Sidekiq.configure_server do |config|
  config.redis = { url: redis_url }

  # Alert when jobs exhaust their retries and land in the dead set; a dead
  # job means merchant data is stale until manually re-run.
  config.death_handlers << lambda do |job, _ex|
    Rails.logger.error("[Sidekiq] Job died: #{job['class']} args=#{job['args'].inspect}")
    Sentry.capture_message("Sidekiq dead job: #{job['class']}", level: :error) if defined?(Sentry) && Sentry.initialized?
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: redis_url }
end
