module Hightops
  module Naming
    class DeadLetterExchange < CommonExchange
      DLX_TAG = 'dlx'.freeze

      def to_s
        [@attributes[:environment], @attributes[:project_name], @attributes[:service_name], DLX_TAG].compact.join('_')
      end
    end
  end
end
