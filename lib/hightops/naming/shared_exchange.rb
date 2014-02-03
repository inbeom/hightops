module Hightops
  module Naming
    class SharedExchange
      def initialize(attributes = {})
        @attributes = default_attributes.merge(attributes)
      end

      def to_s
        [@attributes[:environment], @attributes[:project_name], @attributes[:tag]].compact.join('_')
      end

      protected

      def default_attributes
        {
          environment: Hightops.config.environment,
          project_name: Hightops.config.project_name
        }
      end
    end
  end
end
