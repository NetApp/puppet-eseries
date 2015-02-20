require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_host) do
  before :each do
    @netapp_e_host = { :name => 'netapp_e_host',
                       :storagesystem => 'storagesystem',
                       :groupid => 'group_name',
                       :ports => 'port',
                       :typeindex => 'typeindex' }

    allow(providerclass).to receive(:new).and_wrap_original do |m, *args|
      provider = m.call(*args)
      transport = double
      allow(transport).to receive(:host_group_id).and_raise(RuntimeError)
      allow(provider).to receive(:transport) { transport }
      provider
    end
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_host
  end

  let :providerclass do
    described_class.provide(:macaddr) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:storagesystem, :typeindex, :groupid, :ports, :ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end

    [:storagesystem, :name, :groupid, :typeindex].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name, true
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for typeindex' do
      it_behaves_like 'a string param/property', :typeindex, true
    end
    context 'for groupid' do
      it_behaves_like 'a string param/property', :groupid, true
      it 'should return host group id if group with given name exits' do
        RSpec::Mocks.space.proxy_for(described_class).reset
        allow(providerclass).to receive(:new).and_wrap_original do |m, *args|
          provider = m.call(*args)
          transport = double
          allow(transport).to receive(:host_group_id).with(resource[:storagesystem], resource[:groupid]) { 'groupid' }
          allow(provider).to receive(:transport) { transport }
          provider
        end
        described_class.stubs(:defaultprovider).returns providerclass
        expect(described_class.new(resource)[:groupid]).to eq('groupid')
      end
      it 'should return hash if group with given name do not exits' do
        RSpec::Mocks.space.proxy_for(described_class).reset
        allow(providerclass).to receive(:new).and_wrap_original do |m, *args|
          provider = m.call(*args)
          transport = double
          allow(transport).to receive(:host_group_id).with(resource[:storagesystem], resource[:groupid]) { nil }
          allow(provider).to receive(:transport) { transport }
          provider
        end
        described_class.stubs(:defaultprovider).returns providerclass
        expect(described_class.new(resource)[:groupid]).to eq(:value => resource[:groupid])
      end
    end
    context 'for ports' do
      it_behaves_like 'a string param/property', :ports, true
      it_behaves_like 'a array_matching param', :ports, '80', %w(80 8080)
    end
  end
end
