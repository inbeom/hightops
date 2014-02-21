module Hightops
  module Testing
    class Exchange
      def self.index
        @index ||= {}
      end

      def self.for(options = {})
        name = options[:name] || Hightops::Publisher.new(options).send(:exchange_naming)

        index[name] ||= new(name)
      end

      def initialize(name)
        @name = name
      end

      def publish(payload, options = {})
        events_queues.each do |events, queue|
          if events.include?(options[:routing_key]) || options[:routing_key] == '#'
            queue.push payload
          end
        end
      end

      def bind(events, queue)
        events_queues << [events, queue]
      end

      def events_queues
        @events_queues ||= []
      end
    end

    class Queue < Array
      attr_reader :name

      def self.index
        @index ||= {}
      end

      def self.for(name)
        index[name] ||= new(name: name)
      end

      def initialize(attributes = {})
        @name = attributes[:name]
      end
    end

    module Helpers
      def prepare(*klasses)
        klasses.each do |klass|
          Hightops::Testing::Exchange.for(name: klass.queue_opts[:exchange]).bind(klass.events || klass.default_event_tag, Queue.for(klass.queue_name))
        end
      end
    end
  end
end

module Hightops
  module Worker
    module ClassMethods
      def queue
        Hightops::Testing::Queue.for(self.queue_name)
      end

      def exchange
        Hightops::Testing::Exchange.for(worker_class: self)
      end

      def drain
        Hightops::Testing::Queue.for(self.queue_name).each do |payload|
          new.work(payload)
        end
      end
    end
  end
end

module Hightops
  class Publisher
    def exchange
      Hightops::Testing::Exchange.for(name: exchange_naming.to_s)
    end
  end
end

Hightops.send(:extend, Hightops::Testing::Helpers)
