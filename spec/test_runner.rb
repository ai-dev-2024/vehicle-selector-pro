#!/usr/bin/env ruby
# Comprehensive Test Runner for Vehicle Selector Pro

require_relative "spec_helper"
require_relative "services/app_proxy_signature_verifier_spec"
require_relative "services/bulk_fitment_importer_spec"
require_relative "services/metafield_sync_service_spec"
require_relative "services/fitment_search_service_spec"
require_relative "services/vehicle_hierarchy_service_spec"

puts "=========================================================="
puts "  Running Vehicle Selector Pro Comprehensive Test Suite   "
puts "=========================================================="
