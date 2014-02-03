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
  end

  describe '.subscribe_to_intra_service_event' do
    before { dummy_class.include Hightops::Worker }

    it { expect { dummy_class.subscribe_to_intra_service_event }.to change { dummy_class.queue_name }.from(nil) }
    it { expect { dummy_class.subscribe_to_intra_service_event }.to change { dummy_class.queue_opts }.from(nil) }
  end
end
