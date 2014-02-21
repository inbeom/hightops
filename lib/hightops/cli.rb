require 'thor'
require 'sneakers/runner'

module Hightops
  class CLI < Thor
    class WorkerNotFound < StandardError; end
    class NoWorkers < StandardError; end

    method_option :require, default: '.'
    method_option :environment
    method_option :pid_path, defualt: 'tmp/pids/hightops.pid'

    desc 'start FirstWorker,SecondWorker, ... ,NthWorker', 'Run workers'
    def start(workers)
      load_environment
      setup
      start_runner(workers)
    end

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
      Sneakers.configure daemonize: true, pid_path: options[:pid_path]
    end

    def start_runner(workers)
      workers, missing_workers = Sneakers::Utils.parse_workers(workers)

      raise WorkerNotFound unless missing_workers.empty?
      raise NoWorkers if workers.empty?

      Sneakers::Runner.new(workers).run
    end
  end
end
