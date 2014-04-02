require 'spec_helper'

describe Hightops::Retrier do
  let(:dynamic_dummy_class_name) { "Dummy#{Random.rand(99999999)}" }
  let(:dummy_class) { Class.new.tap { |klass| Object.const_set(dynamic_dummy_class_name, klass) } }
  let(:retrier) { Hightops::Retrier.new(worker_class: dummy_class) }

  before { Sneakers::Worker.configure_logger(Logger.new(STDOUT)) }
  before { dummy_class.include Hightops::Worker }
  before { dummy_class.subscribe_to_intra_service_event }
  around { |example| mock_bunny { example.run } }

  describe '#setup' do
    it { expect { retrier.setup }.to change { MockedBunny.queues } }
    it { expect { retrier.setup }.to change { MockedBunny.exchanges } }
  end

  describe '#publish' do
    let(:payload) { MultiJson.dump({ foo: :bar }) }
    let(:delivery_info) { {} }
    let(:properties) { {} }

    context 'when header is not given' do
      it { expect { retrier.publish(payload, delivery_info, properties) }.to change { MockedBunny.default_exchange.messages } }
    end

    context 'when retry count exceeded the threshold' do
      let(:properties) { { headers: { 'x-hightops-retry-count' => 100 } } }

      it { expect { retrier.publish(payload, delivery_info, properties) }.not_to change { MockedBunny.default_exchange.messages } }
    end
  end
end
