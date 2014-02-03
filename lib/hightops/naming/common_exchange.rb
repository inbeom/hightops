module Hightops
  module Naming
    class CommonExchange
      BACKGROUND_QUEUE_TAG = 'background'.freeze

      def initialize(attributes = {})
        @attributes = default_attributes.merge(attributes)
      end

      def to_s
        [@attributes[:environment], @attributes[:project_name], @attributes[:service_name], BACKGROUND_QUEUE_TAG].compact.join('_')
      end

      protected

      def default_attributes
        {
          environment: Hightops.config.environment,
          project_name: Hightops.config.project_name,
          service_name: Hightops.config.service_name
        }
      end
    end
  end
end
