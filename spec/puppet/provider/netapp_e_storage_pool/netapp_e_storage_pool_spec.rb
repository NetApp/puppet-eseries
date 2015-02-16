require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_storage_pool).provider(:netapp_e_storage_pool) do
  before :each do
    Puppet::Type.type(:netapp_e_storage_pool).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_storage_pool).new(
        :name => 'name',
        :diskids => 'diskids',
        :storagesystem => 'storagesystem',
        :id => 'id',
        :raidlevel => 'raidUnsupported',
        :erasedrives => :false,
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
  end

  describe '#instances' do
    it_behaves_like 'a method with error handling', :get_storage_pools, :instances
    it 'should return an array of current storage pool entries' do
      expect(@transport).to receive(:get_storage_pools) { JSON.parse(File.read(my_fixture('storage_pool-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(1)
      instances.map do |prov|
        { :name => prov.get(:name),
          :id => prov.get(:id),
          :storagesystem => prov.get(:storagesystem),
          :raidlevel => prov.get(:raidlevel),
          :ensure => prov.get(:ensure) }
      end.should == [{ :name => resource[:name],
                       :id => resource[:id],
                       :storagesystem => resource[:storagesystem],
                       :raidlevel => resource[:raidlevel].to_s,
                       :ensure => resource[:ensure] }]
    end
  end
  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_storage_pools) { JSON.parse(File.read(my_fixture('storage_pool-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      resources = { 'name' => resource }
      described_class.prefetch(resources)
      expect(resources['name']).not_to be_nil
    end
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

  describe 'when creating a resource' do
    it_behaves_like 'a method with error handling', :create_storage_pool, :create
    it 'should be able to create it' do
      expect(@transport).to receive(:create_storage_pool).with('storagesystem',
                                                               :name => resource[:name],
                                                               :erasedrives => resource[:erasedrives],
                                                               :raidLevel => resource[:raidlevel],
                                                               :diskDriveIds => resource[:diskids])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end
  describe 'when destroying a resource' do
    it_behaves_like 'a method with error handling', :delete_storage_pool, :destroy
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_storage_pool).with('storagesystem',
                                                               resource[:id])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.set(:id => resource[:id])
      resource.provider.destroy
    end
  end
end
