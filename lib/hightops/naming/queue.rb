module Hightops
  module Naming
    class Queue
      def initialize(attributes = {})
        @attributes = default_attributes.merge(attributes)
      end

      def canonical_worker_name
        @attributes[:worker_class].name.to_s.underscore
      end

      def to_s
        [@attributes[:environment], @attributes[:project_name], @attributes[:service_name], canonical_worker_name].compact.join('_')
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
