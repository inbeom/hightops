def mock_bunny(klass = MockedBunny)
  MockedBunny::Storage.instance.reset

  Hightops::Connection.instance.tap do |connection|
    connection.send(:reset_connection)
    connection.driver = klass
  end

  yield

  Hightops::Connection.instance.tap do |connection|
    connection.send(:reset_connection)
    connection.driver = nil
  end
end

class MockedBunny
  class Binding
    attr_reader :exchange
    attr_reader :queue
    attr_reader :routing_key

    def initialize(exchange, queue, routing_key = nil)
      @exchange = exchange
      @queue = queue
      @routing_key = routing_key || queue.name
    end
  end

  class Queue
    attr_reader :name
    attr_reader :options
    attr_reader :subscriber

    def initialize(name, options = {})
      @name = name
      @options = options
      @messages = []
    end

    def bind(exchange, options = {})
      exchange.bind(Binding.new(exchange, self, options[:routing_key]))
    end

    def subscribe(options = {}, &block)
      @subscriber = block
    end
  end

  class Exchange
    attr_reader :name
    attr_reader :options
    attr_reader :bindings
    attr_reader :messages

    def initialize(name, options = {})
      @name = name
      @options = options
      @messages = []
      @bindings = []
    end

    def publish(payload, options = {})
      messages << payload

      @bindings.each do |binding|
        if binding.routing_key == options[:routing_key]
          binding.queue.messages << payload
        end
      end
    end

    def bind(binding)
      @bindings << binding
    end
  end

  class Storage
    include Singleton

    attr_reader :queues
    attr_reader :exchanges

    def initialize
      reset
    end

    def reset
      @queues = {}
      @exchanges = {}
    end
  end

  attr_reader :options
  attr_reader :status
  attr_reader :prefetch_count
  attr_reader :queues
  attr_reader :exchanges

  def self.exchanges
    Storage.instance.exchanges
  end

  def self.queues
    Storage.instance.queues
  end

  def initialize(_, options = {})
    @options = options
    @queues = {}
    @exchanges = {}
  end

  def start
    @status = :started
  end

  def connected?
    @status == :started
  end

  def create_channel
    self
  end

  def prefetch(prefetch_count)
    @prefetch_count = prefetch_count
  end

  def exchange(name, options = {})
    Storage.instance.exchanges[name] ||= Exchange.new(name, options)
  end

  def default_exchange
    self.class.default_exchange
  end

  def queue(name, options = {})
    self.class.queue(name, options)
  end

  def self.default_exchange
    Storage.instance.exchanges['__DEFAULT__'] ||= Exchange.new('__DEFAULT__')
  end

  def self.queue(name, options = {})
    Storage.instance.queues[name] ||= Queue.new(name, options)
  end
end
