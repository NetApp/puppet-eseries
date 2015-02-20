require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_network_interface) do
  before :each do
    @netapp_e_network_interface = { :macaddr => '0123456789AB',
                                    :storagesystem => 'storagesystem' }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_network_interface
  end

  let :providerclass do
    described_class.provide(:macaddr) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:macaddr]
  end

  describe 'when validating attributes' do
    [:macaddr, :storagesystem].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:id, :controller, :interfacename, :ipv4, :ipv4address, :ipv4mask, :ipv4gateway,
     :ipv4config, :ipv6, :ipv6config, :remoteaccess, :speed].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:macaddr, :storagesystem].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for id' do
      it_behaves_like 'a string param/property', :id, true
    end
    context 'for controller' do
      it_behaves_like 'a string param/property', :controller, true
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for interfacename' do
      it_behaves_like 'a string param/property', :interfacename, true
    end
    context 'for ipv4' do
      it_behaves_like 'a boolish property', :ipv4
    end
    context 'for ipv4address' do
      it_behaves_like 'a IPv4 param/property', :ipv4address
    end
    context 'for ipv4mask' do
      it_behaves_like 'a IPv4 param/property', :ipv4mask
    end
    context 'for ipv4gateway' do
      it_behaves_like 'a IPv4 param/property', :ipv4gateway
    end
    context 'for ipv4config' do
      it_behaves_like 'a enum param/property', :ipv4config, %w(configDhcp configStatic __UNDEFINED)
    end
    context 'for ipv6' do
      it_behaves_like 'a boolish property', :ipv6
    end
    context 'for ipv6address' do
      it_behaves_like 'a IPv6 param/property', :ipv6address
    end
    context 'for ipv6config' do
      it_behaves_like 'a enum param/property', :ipv6config, %w(configStatic configStateless __UNDEFINED)
    end
    context 'for ipv6gateway' do
      it_behaves_like 'a IPv6 param/property', :ipv6gateway
    end
    context 'for ipv6routableaddr' do
      it_behaves_like 'a IPv6 param/property', :ipv6routableaddr
    end
    context 'for remoteaccess' do
      it_behaves_like 'a boolish property', :remoteaccess
    end
    context 'for speed' do
      it_behaves_like 'a enum param/property', :speed, %w(speedNone speedAutoNegotiated speed10MbitHalfDuplex speed10MbitFullDuplex speed100MbitHalfDuplex speed100MbitFullDuplex speed1000MbitHalfDuplex speed1000MbitFullDuplex __UNDEFINED)
    end
  end
end
