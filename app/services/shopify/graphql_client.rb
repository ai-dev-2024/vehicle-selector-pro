require 'net/http'
require 'uri'
require 'json'

module Shopify
  class GraphQLError < StandardError; end
  class ThrottledError < GraphQLError; end
  class AuthenticationError < GraphQLError; end

  class GraphQLClient
    MAX_RETRIES = 3
    DEFAULT_API_VERSION = "2025-07"

    attr_reader :shop, :api_version

    def initialize(shop, api_version: DEFAULT_API_VERSION)
      @shop = shop.is_a?(Shop) ? shop : Shop.find_by!(shopify_domain: shop.to_s)
      @api_version = api_version
    end

    def query(query_string, variables = {})
      execute_with_retry(query_string, variables)
    end

    def mutate(mutation_string, variables = {})
      execute_with_retry(mutation_string, variables)
    end

    private

    def execute_with_retry(query_string, variables = {}, attempts = 0)
      endpoint = "https://#{@shop.shopify_domain}/admin/api/#{@api_version}/graphql.json"
      uri = URI.parse(endpoint)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['X-Shopify-Access-Token'] = @shop.shopify_token
      request['Accept'] = 'application/json'
      request.body = { query: query_string, variables: variables }.to_json

      response = http.request(request)

      case response.code.to_i
      when 200
        parsed = JSON.parse(response.body)
        handle_graphql_response(parsed, query_string, variables, attempts)
      when 429
        handle_throttle(attempts, query_string, variables)
      when 401, 403
        raise AuthenticationError, "Shopify token invalid or expired for #{@shop.shopify_domain}"
      else
        raise GraphQLError, "HTTP #{response.code} error: #{response.body}"
      end
    rescue JSON::ParserError => e
      raise GraphQLError, "Failed to parse JSON response from Shopify: #{e.message}"
    rescue SocketError, Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout => e
      if attempts < MAX_RETRIES
        sleep(2 ** attempts)
        execute_with_retry(query_string, variables, attempts + 1)
      else
        raise GraphQLError, "Network error communicating with Shopify GraphQL: #{e.message}"
      end
    end

    def handle_graphql_response(parsed, query_string, variables, attempts)
      if parsed['errors'].present?
        # Check if throttled
        is_throttled = parsed['errors'].any? { |err| err['extensions'] && err['extensions']['code'] == 'THROTTLED' }
        if is_throttled && attempts < MAX_RETRIES
          sleep_time = extract_restore_rate(parsed) || (2 ** attempts)
          sleep(sleep_time)
          return execute_with_retry(query_string, variables, attempts + 1)
        end

        error_messages = parsed['errors'].map { |e| e['message'] }.join('; ')
        raise GraphQLError, "GraphQL Errors: #{error_messages}"
      end

      # Track cost if available in extensions
      if parsed['extensions'] && parsed['extensions']['cost']
        cost = parsed['extensions']['cost']
        Rails.logger.debug("[ShopifyGraphQL Cost] Requested: #{cost['requestedQueryCost']}, Actual: #{cost['actualQueryCost']}, Available: #{cost.dig('throttleStatus', 'currentlyAvailable')}")
      end

      parsed['data']
    end

    def handle_throttle(attempts, query_string, variables)
      if attempts < MAX_RETRIES
        backoff = 2 ** (attempts + 1)
        Rails.logger.warn("[ShopifyGraphQL Throttle] Received 429 for #{@shop.shopify_domain}. Backing off #{backoff}s...")
        sleep(backoff)
        execute_with_retry(query_string, variables, attempts + 1)
      else
        raise ThrottledError, "Shopify API rate limit exceeded for #{@shop.shopify_domain}"
      end
    end

    def extract_restore_rate(parsed)
      # Extract available points / restore rate if provided by Shopify
      restore_rate = parsed.dig('extensions', 'cost', 'throttleStatus', 'restoreRate')
      return 1.0 if restore_rate.to_f <= 0
      1.0
    end
  end
end
