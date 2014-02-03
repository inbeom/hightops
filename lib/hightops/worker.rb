module Hightops
  # Public: Mixin module for worker classes.
  #
  # Example:
  #
  #   class SomeWorker
  #     include Hightops::Worker
  #
  #     subscribe_to_inter_service_event :upload, events: [:created]
  #   end
  #
  # Workers can be used in two different ways, namely inter-service event
  # processing and intra-service background job processing. Names of AMQP
  # components used for events are determined by project configuration.
  module Worker
    def self.included(base)
      base.include Sneakers::Worker
      base.extend ClassMethods
    end

    module ClassMethods
      # Public: Subscribe to inter-service event through shared exchange.
      # Name of the queue is automatically determined by name of the worker
      # class.
      #
      # tag    - The Symbol tag name of exchange to be subscribed.
      # events - The Array of event types to subscribe to.
      #
      # Returns nothing.
      def subscribe_to_inter_service_event(tag, options = {})
        exchange_naming = Hightops::Naming::SharedExchange.new(tag: tag)
        events = options[:events] || ['#']

        from_queue naming.to_s, options.merge(exchange: exchange_naming.to_s, exchange_type: :topic, routing_key: events)
      end

      # Public: Subscribe to intra-service event through exchange for
      # service-specific background jobs.
      #
      # Returns nothing.
      def subscribe_to_intra_service_event
        exchange_naming = Hightops::Naming::CommonExchange.new

        from_queue naming.to_s, exchange: exchange_naming.to_s, exchange_type: :direct, routing_key: default_event_tag
      end

      # Public: Publish an event to service-specific background jobs exchange.
      #
      # message - Message payload for published event in stringified form.
      # event   - Type for new event.
      #
      # Returns nothing.
      def publish(message)
        Hightops::Publisher.new(worker_class: self).publish(message, default_event_tag)
      end

      # Internal: Recommended naming of specified queue.
      #
      # Returns Hightops::Naming::Queue instance for current class.
      def naming
        Hightops::Naming::Queue.new(worker_class: self)
      end

      # Internal: Default event tag for background jobs.
      #
      # Returns default event tag.
      def default_event_tag
        self.name.to_s.underscore
      end
    end
  end
end
