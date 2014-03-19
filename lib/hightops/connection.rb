module Hightops
  # Public: Handler for Bunny connection.
  class Connection
    include Singleton

    # Public: Instantiates new connection.
    #
    # Returns newly initialized connection object.
    def initialize
      @amqp = Sneakers::Config[:amqp]
      @vhost = Sneakers::Config[:vhost]
      @heartbeat = Sneakers::Config[:heartbeat]
      @mutex = Mutex.new
    end

    # Public: Channel for the connection.
    #
    # Returns new channel associated to the connection.
    def channel
      reset_connection unless connected?

      @channel ||= bunny_connection.create_channel
    end

    protected

    # Internal: Creates and memoizes bunny connection.
    #
    # Returns bunny connection.
    def bunny_connection
      @mutex.synchronize do
        @bunny_connection ||= Bunny.new(@amqp, vhost: @vhost, heartbeat: @heartbeat).tap { |connection| connection.start }
      end
    end

    # Internal: Checks connection status of bunny_connection.
    #
    # Returns true if bunny_connection is alive, false otherwise.
    def connected?
      bunny_connection.connected?
    end

    # Internal: Resets connection handles initialized before.
    #
    # Returns nil.
    def reset_connection
      @bunny_connection = nil
      @channel = nil
    end
  end
end
