require 'singleton'

require 'active_support/hash_with_indifferent_access'
require 'active_support/inflector'
require 'multi_json'
require 'sneakers'

require 'hightops/version'
require 'hightops/configuration'
require 'hightops/connection'
require 'hightops/naming/common_exchange'
require 'hightops/naming/dead_letter_exchange'
require 'hightops/naming/queue'
require 'hightops/naming/retry_queue'
require 'hightops/naming/shared_exchange'
require 'hightops/worker'
require 'hightops/publisher'
require 'hightops/retrier'
require 'hightops/error_handler'

module Hightops
  def self.config(&block)
    Hightops::Configuration.instance.tap do |config|
      if block_given?
        yield config

        serverengine_config = {
          supervisor: true,
          daemon_process_name: "hightops-supervisor-#{config.project_name}-#{config.service_name}",
          worker_process_name: "hightops-worker-#{config.project_name}-#{config.service_name}",
          server_process_name: "hightops-server-#{config.project_name}-#{config.service_name}"
        }

        # We ignore env configuration for Sneakers as it is too tied to its
        # internals.
        #
        # Note: Sneakers 0.1.0 has an additional configuration option to ignore
        # environment variable with Sneakers.not_environmental!
        Sneakers.configure serverengine_config.merge(env: nil, log: config.log, amqp: config.amqp)
      end
    end
  end

  def self.connection
    @connection ||= Hightops::Connection.instance
  end
end
