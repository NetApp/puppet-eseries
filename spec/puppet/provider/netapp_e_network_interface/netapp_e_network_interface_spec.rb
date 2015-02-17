require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_network_interface).provider(:netapp_e_network_interface) do
  before :each do
    Puppet::Type.type(:netapp_e_network_interface).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_network_interface).new(
        :macaddr => '0123456789AB',
        :id => 'id',
        :controller => 'controller',
        :storagesystem => 'storagesystem',
        :interfacename => 'interfacename',
        :ipv4 => true,
        :ipv4address => '10.250.117.116',
        :ipv4mask => '255.255.255.0',
        :ipv4gateway => '10.250.117.101',
        :ipv4config => 'configDhcp',
        :ipv6 => true,
        :ipv6address => '2001:0db8:0000:0000:0000:0000:1428:57ab',
        :ipv6config => 'configStateless',
        :remoteaccess => true,
        :speed => 'speedAutoNegotiated'
    )
  end

  let :provider do
    described_class.new(
        :macaddr => '0123456789AB'
    )
  end
  describe '#instances' do
    it_behaves_like 'a method with error handling', :get_network_interfaces, :instances
    it 'should return an array of current network_interface entries' do
      expect(@transport).to receive(:get_network_interfaces) { JSON.parse(File.read(my_fixture('network_interface-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(1)
      instances.map do |prov|
        { :id => prov.get(:id),
          :macaddr => prov.get(:macaddr),
          :controller => prov.get(:controller),
          :storagesystem => prov.get(:storagesystem),
          :interfacename => prov.get(:interfacename),
          :ipv4 => prov.get(:ipv4),
          :ipv4address => prov.get(:ipv4address),
          :ipv4mask => prov.get(:ipv4mask),
          :ipv4gateway => prov.get(:ipv4gateway),
          :ipv4config => prov.get(:ipv4config),
          :ipv6 => prov.get(:ipv6),
          :ipv6address => prov.get(:ipv6address),
          :ipv6config => prov.get(:ipv6config),
          :ipv6routableaddr => prov.get(:ipv6routableaddr),
          :remoteaccess => prov.get(:remoteaccess),
          :speed => prov.get(:speed) }
      end.should == [{ :id => resource[:id],
                       :macaddr => resource[:macaddr],
                       :controller => resource[:controller],
                       :storagesystem => resource[:storagesystem],
                       :interfacename => resource[:interfacename],
                       :ipv4 => resource[:ipv4],
                       :ipv4address => resource[:ipv4address],
                       :ipv4mask => resource[:ipv4mask],
                       :ipv4gateway => resource[:ipv4gateway],
                       :ipv4config => resource[:ipv4config].to_s,
                       :ipv6 => resource[:ipv6],
                       :ipv6address => { 'address' => '',
                                         'addressState' => { 'addressType' => 'IpV6AddressType',
                                                             'interfaceAddressState' => 'IpConfigState',
                                                             'routerAddressState' => 'IpV6RouterAddressState' } },
                       :ipv6config => resource[:ipv6config].to_s,
                       :ipv6routableaddr => 'ipv6routableaddr',
                       :remoteaccess => resource[:remoteaccess],
                       :speed => resource[:speed].to_s
                     }]
    end
  end
  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_network_interfaces) { JSON.parse(File.read(my_fixture('network_interface-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      current_provider = resource.provider
      resources = { '0123456789AB' => resource }
      described_class.prefetch(resources)
      expect(resources['0123456789AB'].provider).not_to be(current_provider)
    end
  end

  describe 'when modifying a resource' do
    context 'and error occurs' do
      before :each do
        resource.provider.ipv4 = '10.250.117.116'
      end
      it_behaves_like 'a method with error handling', :update_ethernet_interface, :flush
    end
    context 'should be able to modify an existing resource' do
      before :each do
        @expected_body = { :controllerRef => resource[:controller],
                           :interfaceRef => resource[:id] }
        resource.provider.set(:controller => resource[:controller],
                              :id => resource[:id])
      end

      shared_examples 'a changable param/property' do |param_name, expected_name|
        it "if #{param_name} changes" do
          m = resource.provider.method((param_name.to_s + '=').to_sym)
          m.call(resource[param_name])
          @expected_body[expected_name] = resource[param_name]
          expect(@transport).to receive(:update_ethernet_interface).with(resource[:storagesystem], @expected_body)
          allow(resource.provider).to receive(:transport) { @transport }
          resource.provider.flush
        end
      end

      include_examples 'a changable param/property', :ipv4, :ipv4Enabled
      include_examples 'a changable param/property', :ipv4address, :ipv4Address
      include_examples 'a changable param/property', :ipv4mask, :ipv4SubnetMask
      include_examples 'a changable param/property', :ipv4gateway, :ipv4GatewayAddress
      include_examples 'a changable param/property', :ipv4config, :ipv4AddressConfigMethod
      include_examples 'a changable param/property', :ipv6, :ipv6Enabled
      include_examples 'a changable param/property', :ipv6address, :ipv6LocalAddress
      include_examples 'a changable param/property', :ipv6config, :ipv6AddressConfigMethod
      include_examples 'a changable param/property', :ipv6gateway, :ipv6GatewayAddress
      include_examples 'a changable param/property', :speed, :speedSetting
      include_examples 'a changable param/property', :remoteaccess, :enableRemoteAccess
      it 'if ipv6routableaddr changes' do
        resource.provider.ipv6routableaddr = 'ipv6routableaddr'
        @expected_body[:ipv6StaticRoutableAddress] = 'ipv6routableaddr'
        expect(@transport).to receive(:update_ethernet_interface).with(resource[:storagesystem], @expected_body)
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.flush
      end
    end
  end
end
