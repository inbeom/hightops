module Hightops
  class Configuration
    include Singleton

    attr_accessor :project_name, :service_name, :environment, :amqp, :log

    def environment
      @environment || (defined?(Rails) && Rails.env) || ENV['RACK_ENV']
    end

    def log
      @log || defined?(Rails) ? File.join(Rails.root, 'log/hightops.log') : 'hightops.log'
    end
  end
end
