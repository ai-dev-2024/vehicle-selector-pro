source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# .ruby-version is the single source of truth for the Ruby toolchain: CI
# (setup-ruby), the Dockerfile and Dependabot all resolve against it.
ruby file: ".ruby-version"

# Pin to the openssl default gem shipped with the Ruby in .ruby-version so
# Bundler reuses it instead of compiling (slim Docker image, Windows).
gem "openssl", "3.3.3"

gem "rails", "~> 8.1.4"

# Shopify App Integration
gem "shopify_api", "~> 16.3"
gem "shopify_app", "~> 23.0"

# Multi-tenant and Identity
gem "jwt", "~> 3.3"

# Timezone data (required on Windows & JRuby; Linux uses system zoneinfo)
gem "tzinfo-data", platforms: %i[windows jruby]

# Environment variables (.env loading)
gem "dotenv-rails", "~> 3.1"

# Database (dev/test only — production uses Postgres via the pg gem)
gem "sqlite3", "~> 2.10"

# Background Processing & Queuing
gem "redis", "~> 6.0"
gem "sidekiq", "~> 8.0"
# Rails 7.1's redis_cache_store requires the connection_pool 2.x constructor
# signature; 3.x removed it and breaks production boot when REDIS_URL is set.
gem "connection_pool", "~> 3.0"

# Fast JSON Serialization
gem "active_model_serializers", "~> 0.10.14"
gem "oj", "~> 3.17"

# Caching & Performance
# SolidCache (Postgres-backed) is the production default cache store so
# FitmentSearchService caching works across machines even without Redis.
# When REDIS_URL is set (Fly private Redis), redis_cache_store is preferred.
gem "solid_cache", "~> 1.0"

# HTTP Client for Shopify GraphQL & REST
gem "faraday", "~> 2.15"
gem "faraday-retry", "~> 2.0"

# CSV parsing for ACES/PIES/Bulk fitment data
gem "csv", "~> 3.3"

# Server
gem "puma", "~> 8.0"

# Asset pipeline & View styling
gem "polaris_view_components", "~> 3.2"
gem "rack-attack", "~> 6.7"
gem "sprockets-rails", ">= 3.0.0"

# Structured JSON request logging (production)
gem "lograge", "~> 0.15"

# Error tracking (Sentry free tier); no-op without SENTRY_DSN
gem "sentry-rails", "~> 7.1"
gem "sentry-ruby", "~> 7.1"
gem "sentry-sidekiq", "~> 7.1"
group :production do
  # PostgreSQL driver (production database; dev/test use SQLite3)
  gem "pg", "~> 1.7"
end

group :development, :test do
  gem "database_cleaner-active_record", "~> 2.2"
  gem "debug", platforms: %i[mri windows]
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
  gem "rspec-rails", "~> 8.0"
  gem "webmock", "~> 3.34"
end

group :development do
  gem "bullet", "~> 8.3"
  gem "listen", "~> 3.10"
  gem "rubocop", "~> 1.92", require: false
  gem "rubocop-rails", "~> 2.38", require: false
  gem "rubocop-rspec", "~> 3.10", require: false
end

group :test do
  gem "simplecov", "~> 1.3", require: false
end
