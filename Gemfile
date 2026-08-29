source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '>= 3.2.0'

gem 'rails', '~> 7.1.3'

# Shopify App Integration
gem 'shopify_app', '~> 22.0'
gem 'shopify_api', '~> 14.0'

# Multi-tenant and Identity
gem 'jwt', '~> 2.8'

# Database
gem 'pg', '~> 1.5', optional: true
gem 'sqlite3', '~> 1.7'

# Background Processing & Queuing
gem 'sidekiq', '~> 7.2'
gem 'redis', '~> 5.1'

# Fast JSON Serialization
gem 'oj', '~> 3.16'
gem 'active_model_serializers', '~> 0.10.14'

# Caching & Performance
gem 'solid_cache', '~> 0.4.0'

# HTTP Client for Shopify GraphQL & REST
gem 'faraday', '~> 2.9'
gem 'faraday-retry', '~> 2.0'

# CSV parsing for ACES/PIES/Bulk fitment data
gem 'csv', '~> 3.3'

# Server
gem 'puma', '~> 6.4'

# Asset pipeline & View styling
gem 'sprockets-rails', '>= 3.0.0'
gem 'polaris_view_components', '~> 2.5'
gem 'rack-attack', '~> 6.7'

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'rspec-rails', '~> 7.0'
  gem 'factory_bot_rails', '~> 6.4'
  gem 'faker', '~> 3.3'
  gem 'webmock', '~> 3.23'
  gem 'database_cleaner-active_record', '~> 2.2'
end

group :development do
  gem 'rubocop', '~> 1.62', require: false
  gem 'rubocop-rails', '~> 2.24', require: false
  gem 'rubocop-rspec', '~> 2.27', require: false
  gem 'bullet', '~> 7.1'
  gem 'listen', '~> 3.9'
end

group :test do
  gem 'simplecov', '~> 0.22', require: false
end
