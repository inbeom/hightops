require 'spec_helper'

describe Hightops::Worker do
  let(:dynamic_dummy_class_name) { "Dummy#{Random.rand(99999999)}" }
  let(:dummy_class) { Class.new.tap { |klass| Object.const_set(dynamic_dummy_class_name, klass) } }

  describe '.included' do
    before { dummy_class.include Hightops::Worker }

    it { expect(dummy_class).to respond_to(:subscribe_to_inter_service_event) }
    it { expect(dummy_class).to respond_to(:subscribe_to_intra_service_event) }
    it { expect(dummy_class).to respond_to(:publish) }
  end

  describe '.subscribe_to_inter_service_event' do
    before { dummy_class.include Hightops::Worker }

    it { expect { dummy_class.subscribe_to_inter_service_event(:temp) }.to change { dummy_class.queue_name }.from(nil) }
    it { expect { dummy_class.subscribe_to_inter_service_event(:temp) }.to change { dummy_class.queue_opts }.from(nil) }
    it { expect { dummy_class.subscribe_to_inter_service_event(:temp) }.to change { dummy_class.queue_options }.from(nil).to({ retry: 10 }) }
  end

  describe '.subscribe_to_intra_service_event' do
    before { dummy_class.include Hightops::Worker }

    it { expect { dummy_class.subscribe_to_intra_service_event }.to change { dummy_class.queue_name }.from(nil) }
    it { expect { dummy_class.subscribe_to_intra_service_event }.to change { dummy_class.queue_opts }.from(nil) }
    it { expect { dummy_class.subscribe_to_intra_service_event }.to change { dummy_class.queue_options }.from(nil).to({ retry: 10 }) }
  end

  describe '.setup_queue_options' do
    before { dummy_class.include Hightops::Worker }

    context 'when irrelevant option is given' do
      it { expect { dummy_class.setup_queue_options foo: :bar }.to change { dummy_class.queue_options }.to({ retry: 10 }) }
    end

    context 'when retry option is given' do
      it { expect { dummy_class.setup_queue_options retry: false }.to change { dummy_class.queue_options }.to({ retry: false }) }
    end
  end

  describe '#perform' do
    before { dummy_class.include Hightops::Worker }
    before { dummy_class.subscribe_to_intra_service_event }

    context 'when perform is not overrided' do
      it { expect { dummy_class.new.perform }.to raise_error(Hightops::Worker::NotImplemented) }
    end

    context 'when perform is overrided' do
      before { dummy_class.send(:define_method, :perform) { |args = {}| true } }

      it { expect { dummy_class.new.perform }.not_to raise_error }
    end
  end

  describe '#work_with_params' do
    before { dummy_class.include Hightops::Worker }
    before { dummy_class.subscribe_to_intra_service_event }

    let(:payload) { MultiJson.dump({ foo: 'bar' }) }
    let(:delivery_info) { {} }
    let(:properties) { {} }

    context 'when perform is not overrided' do
      it { expect { dummy_class.new.work_with_params(payload, delivery_info, properties) }.to raise_error(Hightops::Worker::NotImplemented) }
    end

    context 'when perform is overrided' do
      around { |example| mock_bunny { example.run } }

      context 'when it ends successfully' do
        before { dummy_class.send(:define_method, :perform) { |args = {}| true } }

        it { expect { dummy_class.new.work_with_params(payload, delivery_info, properties) }.not_to raise_error }
      end

      context 'when it does not end successfully' do
        let(:retry_queue_name) { Hightops::Naming::RetryQueue.new(worker_class: dummy_class).to_s }

        before { dummy_class.send(:define_method, :perform) { |args = {}| raise(StandardError.new) } }

        it { expect { dummy_class.new.work_with_params(payload, delivery_info, properties) }.to raise_error(StandardError) }
        it { expect { dummy_class.new.work_with_params(payload, delivery_info, properties) rescue nil }.to change { MockedBunny.default_exchange.messages } }
      end
    end
  end

  describe '#setup_retrier' do
    before { Sneakers::Worker.configure_logger(Logger.new(STDOUT)) }
    before { dummy_class.include Hightops::Worker }
    before { dummy_class.subscribe_to_intra_service_event }
    around { |example| mock_bunny { example.run } }

    context 'when retrying is disabled' do
      before { dummy_class.send(:setup_queue_options, retry: false) }

      it { expect { dummy_class.new.setup_retrier }.not_to change { MockedBunny.queues } }
    end

    context 'when retrying is enabled as default' do
      before { dummy_class.send(:setup_queue_options) }

      it { expect { dummy_class.new.setup_retrier }.to change { MockedBunny.queues } }
    end
  end
end
