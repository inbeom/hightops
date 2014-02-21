require 'thor'
require 'sneakers/runner'

module Hightops
  class CLI < Thor
    class WorkerNotFound < StandardError; end
    class NoWorkers < StandardError; end

    method_option :require, default: '.'
    method_option :environment

    def run(workers)
      load_environment
      setup
      start_runner
    end

    default_task :run

    private

    def load_environment
      ENV['RACK_ENV'] = ENV['RAILS_ENV'] = options[:environment]

      if File.directory?(options[:require])
        require 'rails'
        require File.expand_path("#{options[:require]}/config/environment.rb")
        ::Rails.application.eager_load!
      else
        require options[:require]
      end
    end

    def setup
      Sneakers.configure daemonize: true
    end

    def start_runner
      workers, missing_workers = Sneakers::Utils.parse_workers(workers)

      raise WorkerNotFound unless missing_workers.empty?
      raise NoWorkers if workers.empty?

      Sneakers::Runner.new(workers).run
    end
  end
end
