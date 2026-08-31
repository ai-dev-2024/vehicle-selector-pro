# Rails-integrated RSpec setup. Unlike spec_helper.rb (the standalone mock
# harness used by spec/test_runner.rb), this boots the full Rails app so
# request specs exercise routing, middleware, HMAC verification, and JSON
# responses through the real stack.
ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rspec/rails"

# Shared helpers for request specs (authenticated admin session, etc.).
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    # Request specs assert on enqueued jobs; never execute them inline.
    ActiveJob::Base.queue_adapter = :test
    Rails.cache.clear
  end

  # Keep metafield-sync side effects out of most specs; individual specs can
  # opt back in with ActiveJob::Base.queue_adapter = :test around their calls.
  config.before do
    allow(Metafields::ProductMetafieldSyncJob).to receive(:perform_later)
    allow(Metafields::BatchSyncJob).to receive(:perform_later)
  end
end
