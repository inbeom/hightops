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

### Configuration

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

#### Publishing Inter-service Messages

`Hightops::Publisher` provides interface for publishing messages:

```ruby
Hightops::Publisher.new(tag: :uploads).publish(:created, first: 1, second: 2)
```

## Deployment

Hightops provides Capistrano recipe compatible with Capistrano `~> 3.0`. To
load the recipe, add this line in your `Capfile`:

```ruby
require 'hightops/capistrano'
```

You should set proper absolute path of your Hightops pid file and list of worker
classes with Capistrano variables to run the recipe properly.

```ruby
set :hightops_pid, "#{shared_path}/tmp/pids/hightops.pid"
set :hightops_workers, ['FirstWorker', 'SecondWorker']
```

## Testing

Hightops provides stub RabbitMQ objects for testing environment.  Before running
your test suite, load the stub objects as:

```ruby
# On top of spec_helper.rb

require 'hightops/testing'
```

### Testing Intra-service Background Job Processor

Set up proper queue bindings subject for your testing before running your test
suite as:

```ruby
Hightops.prepare(YourWorker, AnotherWorker, ...)
```

For example, in RSpec, it can be added as `before_suite` callback.

```ruby
RSpec.configure do |config|
  config.before(:suite) do
    Hightops.prepare(YourWorker, AnotherWorker, ...)
  end
end
```

After setting up properly, perform testing as:

```ruby
it { expect { YourWorker.publish(params) }.to change { YourWorker.queue.length }.by(1) }
```

### Testing Inter-service Message Publisher

Every published messages are stored in stubbed exchanges, and you can retrieve
them as Arrays as listed below:

```ruby
it { expect { Hightops::Publisher.new(:my_events).publish(:tag, payload) }.to change { Hightops::Publisher.new(:my_events).exchange.events_tagged(:tag) }.by(1) }
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/hightops/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
