module Hightops
  class Configuration
    include Singleton

    attr_accessor :project_name, :service_name, :environment

    def environment
      @environment || (defined?(Rails) && Rails.env) || ENV['RACK_ENV']
    end
  end
end
