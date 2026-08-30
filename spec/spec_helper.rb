ENV["RAILS_ENV"] ||= "test"

require "minitest/autorun"
require "json"
require "openssl"
require "base64"
require "stringio"

# Core Object extensions for standalone test execution
class Object
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  # rubocop:disable-next Rails/Present -- this IS the definition of present?
  def present?
    !blank?
  end

  def presence
    self if present?
  end

  def in?(collection)
    collection.include?(self)
  end
end

class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    strip.empty?
  end
end

# Load mock environment for unit tests
module ShopifyApp
  class Configuration
    attr_accessor :secret, :api_key, :api_version

    def initialize
      @secret = "vsp_test_api_secret_4493019349810"
      @api_key = "vsp_test_api_key"
      @api_version = "2024-04"
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end
end

module Rails
  class Cache
    def initialize
      @store = {}
    end

    def fetch(key, _options = {}, &block)
      if @store.key?(key)
        @store[key]
      elsif block_given?
        val = block.call
        @store[key] = val
        val
      end
    end

    def write(key, value, _options = {})
      @store[key] = value
    end

    def read(key)
      @store[key]
    end

    def delete(key)
      @store.delete(key)
    end

    def clear
      @store.clear
    end
  end

  class Logger
    def info(msg); end
    def warn(msg); end
    def error(msg); end
    def debug(msg); end
  end

  def self.cache
    @cache ||= Cache.new
  end

  def self.logger
    @logger ||= Logger.new
  end

  # Minimal environment object for standalone tests. A plain Struct with
  # predicate methods (avoiding OpenStruct, which RuboCop discourages).
  Env = Struct.new(:environment) do
    def test?
      environment == :test
    end

    def development?
      environment == :development
    end

    def production?
      environment == :production
    end
  end

  def self.env
    @env ||= Env.new(:test)
  end
end

# Load Service Objects
require_relative "../app/services/app_proxy_signature_verifier"
require_relative "../app/services/bulk_fitment_importer"
