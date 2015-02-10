require 'spec/spec_helper'

describe Puppet::Util::NetworkDevice::Netapp_e::Device do
  before(:each) do
    @api = double(:api)
    allow(@api).to receive(:login)
    allow(NetApp::ESeries::Api).to receive(:new) { @api }
    @password = 'my_password'
    @url = "http://user:#{@password}@example.com"
    @device = Puppet::Util::NetworkDevice::Netapp_e::Device.new(@url)
  end

  it 'should have url attr accessible' do
    url = double(:url)
    @device.url = url
    expect(@device.url).to be(url)
  end

  it 'should have transport attr accessible' do
    transport = double(:transport)
    @device.transport = transport
    expect(@device.transport).to be(transport)
  end

  context 'initialize:' do
    it 'should not log password when connecting to device' do
      expect(Puppet).not_to receive(:debug).with(include(@password))
      Puppet::Util::NetworkDevice::Netapp_e::Device.new(@url)
    end

    it 'should set url on object' do
      expect(@device.url).to eq(URI.parse(@url))
    end

    it 'should set transport on object' do
      expect(@device.transport).to eq(@api)
    end

    it 'should raise ArgumentError if password is not provided' do
      @url = 'http://user@example.com'
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new @url }.to raise_error ArgumentError, 'no password specified'
    end

    it 'should raise ArgumentError if user is not provided' do
      @url = 'http://example.com'
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new @url }.to raise_error ArgumentError, 'no user specified'
    end

    it 'should accept http scheme' do
      @url = 'http://user:password@example.com'
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new @url }.not_to raise_error
    end

    it 'should accept https scheme' do
      @url = 'https://user:password@example.com'
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new @url }.not_to raise_error
    end

    it 'should not accept other scheme types' do
      @url = 'ftp://user:password@example.com'
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new @url }.to raise_error ArgumentError, 'Invalid scheme ftp. Must be http or https.'
    end
    it 'should create transport when port is specified' do
      url = 'http://user:password@example.com:8123'
      expect(NetApp::ESeries::Api).to receive(:new).with('user', 'password', 'http://example.com:8123', true, 15) { @api }
      expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new url }.not_to raise_error
    end
    context 'and path is not specified' do
      it 'should create transport' do
        url = 'http://user:password@example.com'
        expect(NetApp::ESeries::Api).to receive(:new).with('user', 'password', 'http://example.com:80', true, 15) { @api }
        expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new url }.not_to raise_error
      end
    end
    context 'and path is specified' do
      it 'should create transport' do
        url = 'http://user:password@example.com/api/'
        expect(NetApp::ESeries::Api).to receive(:new).with('user', 'password', 'http://example.com:80/api', true, 15) { @api }
        expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new url }.not_to raise_error
      end
      it 'should create transport without slash on end' do
        url = 'http://user:password@example.com/api'
        expect(NetApp::ESeries::Api).to receive(:new).with('user', 'password', 'http://example.com:80/api', true, 15) { @api }
        expect { Puppet::Util::NetworkDevice::Netapp_e::Device.new url }.not_to raise_error
      end
    end
  end

  context 'facts' do
    it 'should return facts' do
      facts = double('Facts')
      retrieved_facts = double
      allow(facts).to receive(:retrieve) { retrieved_facts }
      expect(Puppet::Util::NetworkDevice::Netapp_e::Facts).to receive(:new).once.with(@api) { facts }
      expect(@device.facts).to be(retrieved_facts)
      expect(@device.facts).to be(retrieved_facts)
    end
  end
end
