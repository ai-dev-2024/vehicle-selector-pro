#!/usr/bin/env ruby
# Test entrypoint for Vehicle Selector Pro.
#
# The canonical suite is RSpec (boots the real Rails app; request, job, model
# and service specs). The App Proxy integration suite is Minitest-based and
# runs standalone. This wrapper runs both and exits non-zero on any failure.
#
# Usage: ruby spec/test_runner.rb

rspec_ok = system("bundle exec rspec spec --exclude-pattern 'spec/integration/*'")
integration_ok = system("ruby spec/integration/app_proxy_integration_test.rb")

puts "=" * 58
puts "RSpec:        #{rspec_ok ? 'PASS' : 'FAIL'}"
puts "Integration:  #{integration_ok ? 'PASS' : 'FAIL'}"
puts "=" * 58

exit(rspec_ok && integration_ok ? 0 : 1)
