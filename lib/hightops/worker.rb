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
    # Public: Error indicating missing implementation of #perform method
    class NotImplemented < StandardError; end

    def self.included(base)
      base.send(:include, Sneakers::Worker)
      base.send(:include, InstanceMethods)
      base.extend ClassMethods
    end

    module InstanceMethods
      # Public: Interface to Sneakers::Queue object which Worker is holding.
      attr_reader :queue

      # Internal: Parse JSON payload as preprocessing to perform desired
      # task for the worker and send acknowledgement.
      #
      # payload       - The String of JSON payload.
      # delivery_info - Delivery information of the message.
      # properties    - Properties associated with the message.
      #
      # Returns nothing.
      def work_with_params(payload, delivery_info, properties)
        begin
          perform HashWithIndifferentAccess.new(MultiJson.load(payload))
        rescue => exception
          unless exception.is_a?(Hightops::Worker::NotImplemented)
            retrier.publish(payload, delivery_info, properties) if self.class.queue_options[:retry]

            Hightops::ErrorHandler.new.handle_exception(exception, delivery_info)
          end

          raise exception
        end

        ack!
      end

      # Public: After being overriden, performs desired task for the worker.
      #
      # arguments - The Hash containing arguments in concern.
      #
      # Returns nothing.
      def perform(arguments = {})
        raise Hightops::Worker::NotImplemented.new
      end

      # Public: Set up queue and exchange for retrying failed jobs.
      #
      # Returns nothing.
      def setup_retrier
        retrier.setup if self.class.queue_options[:retry]
      end

      # Internal: Retrier object for the worker class.
      #
      # Returns Retrier object.
      def retrier
        @retrier ||= Hightops::Retrier.new(worker_class: self.class)
      end
    end

    module ClassMethods
      # Public: Naming object for exchange in concern.
      attr_reader :exchange_naming
      # Public: List of events to which the worker queue listens.
      attr_reader :events
      # Public: Flag indicates whether retrying is enabled or not.
      attr_reader :queue_options

      # Public: Subscribe to inter-service event through shared exchange.
      # Name of the queue is automatically determined by name of the worker
      # class.
      #
      # tag     - The Symbol tag name of exchange to be subscribed.
      # options - Additional options for the event binding.
      #           :events - The Array of event types to subscribe to.
      #
      # Returns nothing.
      def subscribe_to_inter_service_event(tag, options = {})
        @exchange_naming = Hightops::Naming::SharedExchange.new(tag: tag)
        @events = options[:events] || ['#']
        setup_queue_options(options)

        from_queue naming.to_s, options.merge(exchange: @exchange_naming.to_s, exchange_type: :topic, routing_key: @events)
      end

      # Public: Subscribe to intra-service event through exchange for
      # service-specific background jobs.
      #
      # options - Additional options for the event binding.
      #
      # Returns nothing.
      def subscribe_to_intra_service_event(options = {})
        @exchange_naming = Hightops::Naming::CommonExchange.new
        setup_queue_options(options)

        from_queue naming.to_s, exchange: exchange_naming.to_s, exchange_type: :direct, routing_key: default_event_tag
      end

      # Public: Publish an event to service-specific background jobs exchange.
      #
      # message - The Hash containing message payload for published event.
      # event   - Type for new event.
      #
      # Returns nothing.
      def publish(message = {})
        Hightops::Publisher.new(worker_class: self).publish(default_event_tag, message)
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

      # Internal: Set up queue options for the Worker class.
      #
      # Returns queue options.
      def setup_queue_options(options = {})
        options[:retry] = 10 unless options.keys.include?(:retry)

        @queue_options = options.slice(:retry)
      end
    end
  end
end
