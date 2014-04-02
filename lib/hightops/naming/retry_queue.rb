module Hightops
  module Naming
    class RetryQueue < Queue
      def to_s
        [@attributes[:environment], @attributes[:project_name], @attributes[:service_name], canonical_worker_name, 'retry'].compact.join('_')
      end
    end
  end
end
