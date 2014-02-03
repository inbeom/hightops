# Hightops

On top of RabbitMQ and Sneakers, Hightops implements communication protocol
for inter- and intra-service messaging system.

## Installation

Add this line to your application's Gemfile:

    gem 'hightops'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hightops

## Usage

### Configuring

Create `config/hightops.rb` as:

```ruby
Hightops.config do |config|
  config.project_name = 'limit' # Top-level project name
  config.service_name = 'server' # Specific service name
end

# Use your own AMQP server address
Sneakers.configure 'amqp://guest:guest@localhost:5672'
```

### As Intra-service Background Job Processor

Set up a worker:

```ruby
class BackgroundWorker
  include Hightops::Worker

  subscribe_to_intra_service_event

  def perform(message = {})
    # Do work
  end
end
```

Publish messages as:

```ruby
BackgroundWorker.publish(first: 1, second: 2)
```

### As Inter-service Message Processor

Set up a worker:

```ruby
class UploadCreationProcessor
  include Hightops::Worker

  subscribe_to_inter_service_event :uploads, events: [:created]

  def perform(message = {})
    # Do work
  end
end
```

By default, if `:events` option is not specified, queue of the worker listens
to every events published using same tag.

### Publishing Inter-service Messages

`Hightops::Publisher` provides interface for publishing messages:

```ruby
Hightops::Publisher.new(tag: :uploads).publish(:created, first: 1, second: 2)
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/hightops/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
