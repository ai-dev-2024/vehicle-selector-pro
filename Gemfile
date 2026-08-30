source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby ">= 3.2.0"

# Pin exactly to the OpenSSL version bundled with Ruby 3.2 (avoids compiling
# the standalone openssl gem from source on Windows / machines without headers)
gem "openssl", "3.1.0"

gem "rails", "~> 7.1.3"

# Shopify App Integration
gem "shopify_api", "~> 14.0"
gem "shopify_app", "~> 22.0"

# Multi-tenant and Identity
gem "jwt", "~> 2.8"

# Timezone data (required on Windows & JRuby; Linux uses system zoneinfo)
gem "tzinfo-data", platforms: %i[windows jruby]

# Environment variables (.env loading)
gem "dotenv-rails", "~> 3.1"

# Database
gem "sqlite3", "~> 1.7"

# Background Processing & Queuing
gem "redis", "~> 5.1"
gem "sidekiq", "~> 7.2"
# Rails 7.1's redis_cache_store requires the connection_pool 2.x constructor
# signature; 3.x removed it and breaks production boot when REDIS_URL is set.
gem "connection_pool", "~> 2.4"

# Fast JSON Serialization
gem "active_model_serializers", "~> 0.10.14"
gem "oj", "~> 3.16"

# Caching & Performance
# NOTE: solid_cache was removed — the SolidCache fallback in production.rb
# needed a solid_cache_entries migration this app never shipped. Production
# caching runs on Redis (Fly private Redis) via redis_cache_store.

# HTTP Client for Shopify GraphQL & REST
gem "faraday", "~> 2.9"
gem "faraday-retry", "~> 2.0"

# CSV parsing for ACES/PIES/Bulk fitment data
gem "csv", "~> 3.3"

# Server
gem "puma", "~> 6.4"

# Asset pipeline & View styling
gem "polaris_view_components", "~> 2.5"
gem "rack-attack", "~> 6.7"
gem "sprockets-rails", ">= 3.0.0"

group :production do
  # PostgreSQL driver (production database; dev/test use SQLite3)
  gem "pg", "~> 1.5"
end

group :development, :test do
  gem "database_cleaner-active_record", "~> 2.2"
  gem "debug", platforms: %i[mri windows]
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.3"
  gem "rspec-rails", "~> 7.0"
  gem "webmock", "~> 3.23"
end

group :development do
  gem "bullet", "~> 7.1"
  gem "listen", "~> 3.9"
  gem "rubocop", "~> 1.62", require: false
  gem "rubocop-rails", "~> 2.24", require: false
  gem "rubocop-rspec", "~> 2.27", require: false
end

group :test do
  gem "simplecov", "~> 0.22", require: false
end
