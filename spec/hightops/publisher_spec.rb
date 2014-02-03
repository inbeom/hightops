require 'spec_helper'

describe Hightops::Publisher do
  describe '#exchange_naming' do
    context 'when it is initialized with worker class' do
      let(:dynamic_dummy_class_name) { "Dummy#{Random.rand(99999999)}" }
      let(:dummy_class) { Class.new.tap { |klass| Object.const_set(dynamic_dummy_class_name, klass) } }
      let(:publisher) { Hightops::Publisher.new worker_class: dummy_class }
      let(:naming) { publisher.send(:exchange_naming) }

      before { dummy_class.include Hightops::Worker }

      it { expect(naming.to_s).to include(Hightops::Naming::CommonExchange::BACKGROUND_QUEUE_TAG) }
    end

    context 'when it is initialized with tag' do
      let(:tag) { 'hightops-tag' }
      let(:publisher) { Hightops::Publisher.new tag: tag }
      let(:naming) { publisher.send(:exchange_naming) }

      it { expect(naming.to_s).to include(tag) }
    end
  end
end
