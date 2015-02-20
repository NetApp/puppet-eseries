require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_host_group).provider(:netapp_e_host_group) do
  before :each do
    Puppet::Type.type(:netapp_e_host_group).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_host_group).new(
        :name => 'name',
        :storagesystem => 'storagesystem',
        :hosts => 'some hosts',
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
  end

  describe 'when asking exists?' do
    it 'should return true if resource is present' do
      resource.provider.set(:ensure => :present)
      resource.provider.should be_exists
    end
    it 'should return false if resource is absent' do
      resource.provider.set(:ensure => :absent)
      resource.provider.should_not be_exists
    end
  end

  describe '#instances' do
    it_behaves_like 'a method with error handling', :get_host_groups, :instances
    it 'should return an array of current host_groups entries' do
      expect(@transport).to receive(:get_host_groups) { JSON.parse(File.read(my_fixture('host_groups-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(1)
      instances.map do |prov|
        { :name => prov.get(:name),
          :id => prov.get(:id),
          :storagesystem => prov.get(:storagesystem),
          :ensure => prov.get(:ensure)
        }
      end.should == [{ :name => resource[:name],
                       :storagesystem => resource[:storagesystem],
                       :ensure => resource[:ensure],
                       :id => 'id' }]
    end
  end

  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_host_groups) { JSON.parse(File.read(my_fixture('host_groups-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      current_provider = resource.provider
      resources = { 'name' => resource }
      described_class.prefetch(resources)
      expect(resources['name']).not_to be(current_provider)
    end
  end

  describe 'when creating a resource' do
    it_behaves_like 'a method with error handling', :create_host_group, :create
    it 'should be able to create it' do
      expect(@transport).to receive(:create_host_group).with('storagesystem',
                                                             :hosts => resource[:hosts],
                                                             :name => resource[:name])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
    describe 'when destroying a resource' do
      it_behaves_like 'a method with error handling', :delete_host_group, :destroy
      it 'should be able to delete it' do
        expect(@transport).to receive(:delete_host_group).with(resource[:storagesystem], 'id')
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.set(:id => 'id')
        resource.provider.destroy
      end
    end
  end
end
