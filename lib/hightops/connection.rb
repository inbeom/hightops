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
    end

    # Public: Channel for the connection.
    #
    # Returns new channel associated to the connection.
    def channel
      @channel ||= bunny_connection.create_channel
    end

    protected

    # Internal: Creates and memoizes bunny connection.
    #
    # Returns bunny connection.
    def bunny_connection
      @bunny_connection ||= Bunny.new(@amqp, vhost: @vhost, heartbeat: @heartbeat).tap { |connection| connection.start }
    end
  end
end
