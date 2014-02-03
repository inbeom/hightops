module Hightops
  # Public: Class used for publishing events to specified exchange.
  #
  # Example:
  #
  #   Hightops::Publisher.new(options).publish(payload, event)
  class Publisher
    # Public: Instantiates new publisher.
    #
    # options - The Hash options for publisher.
    #           :worker_class - The Class of worker for background jobs.
    #           :tag          - The Symbol of tag name of exchange to publish
    #                           for inter-service events.
    #
    # Returns newly initialized publisher object.
    def initialize(options = {})
      @worker_class = options[:worker_class]
      @tag = options[:tag]
    end

    # Public: Publishes an event through proper exchange.
    #
    # payload - The string for payload of the event.
    # event   - The string of tag for the event. Acts as AMQP routing key
    #           internally.
    #
    # Returns nothing.
    def publish(event, payload = {})
      exchange.publish(MultiJson.dump(payload), routing_key: event)
    end

    protected

    # Internal: Exchange object for the publisher.
    #
    # Returns exchange object.
    def exchange
      @exchange ||= Hightops.connection.channel.exchange(exchange_naming.to_s, type: exchange_type, durable: true)
    end

    # Internal: Naming of exchange object for the publisher.
    #
    # Returns exchange naming object.
    def exchange_naming
      @exchange_naming ||= if @worker_class
        Hightops::Naming::CommonExchange.new
      else
        Hightops::Naming::SharedExchange.new(tag: @tag)
      end
    end

    # Internal: Type of exchange for the publisher.
    #
    # Returns The Symbol of exchange type.
    def exchange_type
      @exchange_type ||= @worker_class ? :direct : :topic
    end
  end
end
