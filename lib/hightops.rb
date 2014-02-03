require 'singleton'

require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'multi_json'
require 'sneakers'

require 'hightops/version'
require 'hightops/configuration'
require 'hightops/connection'
require 'hightops/naming/common_exchange'
require 'hightops/naming/queue'
require 'hightops/naming/shared_exchange'
require 'hightops/worker'
require 'hightops/publisher'

module Hightops
  def self.config(&block)
    Hightops::Configuration.instance.tap do |config|
      if block_given?
        yield config

        # We ignore env configuration for Sneakers as it is too tied to its
        # internals.
        Sneakers.configure env: nil
      end
    end
  end

  def self.connection
    @connection ||= Hightops::Connection.instance
  end
end
