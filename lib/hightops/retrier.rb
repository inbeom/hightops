module Hightops
  class Retrier
    # Public: Instantiates a new Retrier object with given options.
    #
    # options - Options for Retrier object.
    #           :worker_class - Associated worker class.
    #
    # Returns newly initialized Retrier object.
    def initialize(options = {})
      @worker_class = options[:worker_class]
    end

    # Public: Sets up exchange and queue for retrial.
    #
    # Returns nothing.
    def setup
      queue = @worker_class.new.queue

      Hightops::Connection.instance.channel.queue(retry_queue_naming.to_s, durable: true, arguments: queue_arguments)
      Hightops::Connection.instance.channel.queue(queue.name, durable: queue.opts[:durable]).bind(dead_letter_exchange, routing_key: queue.name)
    end

    # Public: Publish a retrying event to retrial queue.
    #
    # Returns nothing.
    def publish(payload, delivery_info, properties)
      if !properties[:headers]
        Hightops::Connection.instance.channel.default_exchange.publish(payload, routing_key: retry_queue_naming.to_s, content_type: 'application/json', expiration: interval_for(1), headers: { 'x-hightops-retry-count' => 1 })
      else
        if properties[:headers]['x-hightops-retry-count'] && properties[:headers]['x-hightops-retry-count'] >= maximum_retry_count
          # Exceeded maximum retry count
        else
          retry_count = (properties[:headers]['x-hightops-retry-count'] || 0) + 1

          Hightops::Connection.instance.channel.default_exchange.publish(payload, routing_key: retry_queue_naming.to_s, content_type: 'application/json', expiration: interval_for(retry_count), headers: { 'x-hightops-retry-count' => retry_count })
        end
      end
    end

    # Public: Dead letter exchange for the Retrier object.
    #
    # Returns Bunny::Exchange object for dead letter exchange.
    def dead_letter_exchange
      @dead_letter_exchange ||= Hightops.connection.channel.exchange(dlx_naming.to_s, type: 'direct', durable: true)
    end

    protected

    # Internal: Options used when creating retry queues.
    #
    # Returns Hash of options.
    def queue_arguments
      { 'x-dead-letter-exchange' => dlx_naming.to_s, 'x-dead-letter-routing-key' => @worker_class.naming.to_s }
    end

    # Internal: Retrieves interval (in milliseconds) used for retrials.
    #
    # count - Retrial count.
    #
    # Returns Integer of interval.
    def interval_for(count)
      1000 * (((count - 1) ** 4) + 15 + (rand(30) * count))
    end

    # Internal: Naming for dead letter exchange.
    #
    # Returns Hightops::Naming::DeadLetterExchange object.
    def dlx_naming
      @dlx_naming ||= Hightops::Naming::DeadLetterExchange.new
    end

    # Internal: Naming for retry queue.
    #
    # Returns Hightops::Naming::RetryQueue object.
    def retry_queue_naming
      @retry_queue_naming ||= Hightops::Naming::RetryQueue.new(worker_class: @worker_class)
    end

    def maximum_retry_count
      @worker_class.queue_options[:retry] || 0
    end
  end
end
