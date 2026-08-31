# Sentry error tracking. Enabled only when SENTRY_DSN is present (set on Fly
# as a secret); otherwise the SDK stays dormant so local/CI runs are no-ops.
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    config.environment = ENV.fetch("SENTRY_ENV", Rails.env)
    config.release = ENV["GIT_SHA"] || ENV["FLY_IMAGE_REF"].to_s.split("@").last || "local"
    config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.1").to_f
    config.sidekiq.capture_exception = true
  end
end
