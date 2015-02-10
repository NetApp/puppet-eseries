require 'spec/spec_helper'

describe Puppet::Provider::Netapp_e do
  before(:each) do
    @netapp_e = Puppet::Provider::Netapp_e.new
    @device = double(:device)
    @transport = double(:transport)
    allow(@device).to receive(:transport) { @transport }
  end

  it 'device attr should not be accessible' do
    device = double(:device)
    expect { @netapp_e.device = device }.to raise_error NoMethodError
    expect { @netapp_e.device }.to raise_error NoMethodError
  end

  context 'transport' do
    context 'and :url fact isnot  set' do
      it 'should return current device transport' do
        expect(Puppet::Util::NetworkDevice).to receive(:current) { @device }
        expect(@netapp_e.transport).to be(@transport)
      end

      it 'should retrieve NetworkDevice.current only once' do
        expect(Puppet::Util::NetworkDevice).to receive(:current).once { @device }
        expect(@netapp_e.transport).to be(@transport)
        expect(@netapp_e.transport).to be(@transport)
      end

      it 'should raise Error if device is not initialized' do
        expect { @netapp_e.transport }.to raise_error Puppet::Error
      end
    end

    context 'and :url fact is set' do
      before(:each) do
        @url = 'http://user:password@example.com/'
        allow(Facter).to receive(:value).with(:url) { @url }
      end
      it 'should return new device transport' do
        expect(Puppet::Util::NetworkDevice::Netapp_e::Device).to receive(:new).with(@url) { @device }
        expect(@netapp_e.transport).to be(@transport)
      end
      it 'should retrieve NetworkDevice.current only once' do
        expect(Puppet::Util::NetworkDevice::Netapp_e::Device).to receive(:new).once { @device }
        expect(@netapp_e.transport).to be(@transport)
        expect(@netapp_e.transport).to be(@transport)
      end
    end
    after(:each) do
      Puppet::Provider::Netapp_e.instance_variable_set(:@device, nil)
    end
  end
end
