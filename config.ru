# Use the public utility method in Rails in order to not have to require `active_support/all`
# Load Rails application
require_relative "config/application"

# Initialize Rails application
Rails.application.initialize!

# Start
run Rails.application
