require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_volume).provider(:netapp_e_volume) do
  before :each do
    Puppet::Type.type(:netapp_e_volume).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_volume).new(
        :name => 'name',
        :id => 'id',
        :storagesystem => 'storagesystem',
        :storagepool => 'storagepool',
        :ensure => :present,
        :sizeunit => 'b',
        :size => '2',
        :segsize => '1',
        :dataassurance => :true

    )
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
  end

  let :mappings do
    [{ 'lunMappingRef' => '',
       'lun' => 0,
       'ssid' => 0,
       'perms' => 0,
       'volumeRef' => '',
       'type' => 'LUNMappingType',
       'mapRef' => '' }]
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
    it_behaves_like 'a method with error handling', :get_volumes, :instances
    it 'should return an array of current volumes entries' do
      expect(@transport).to receive(:get_volumes) { JSON.parse(File.read(my_fixture('volumes-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(2)
      instances.map do |prov|
        { :name => prov.get(:name),
          :id => prov.get(:id),
          :storagesystem => prov.get(:storagesystem),
          :mappings => prov.get(:mappings),
          :ensure => prov.get(:ensure) }
      end.should == [{ :name => 'volume-name',
                       :id => 'volume-id',
                       :storagesystem => resource[:storagesystem],
                       :ensure => resource[:ensure],
                       :mappings => mappings
                     }, { :name => 'thin-volume-name',
                          :id => 'thin-volume-id',
                          :storagesystem => resource[:storagesystem],
                          :ensure => resource[:ensure],
                          :mappings => mappings
                     }]
    end
  end

  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_volumes) { JSON.parse(File.read(my_fixture('volumes-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      current_provider = resource.provider
      resources = { 'volume-name' => resource }
      described_class.prefetch(resources)
      expect(resources['volume-name']).not_to be(current_provider)
    end
  end

  describe 'when creating' do
    it_behaves_like 'a method with error handling', :storage_pool_id, :create
    context 'a volume' do
      before :each do
        expect(@transport).to receive(:storage_pool_id).with(resource[:storagesystem], resource[:storagepool]) { 'poolId' }
      end
      it_behaves_like 'a method with error handling', :create_volume, :create
      it 'should be able to create it' do
        expect(@transport).to receive(:create_volume).with('storagesystem',
                                                           :poolId => 'poolId',
                                                           :sizeUnit => resource[:sizeunit],
                                                           :dataAssuranceEnabled => resource[:dataassurance],
                                                           :segSize => resource[:segsize],
                                                           :size => resource[:size],
                                                           :name => resource[:name])
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'a thin-volume' do
      before :each do
        resource[:thin] = true
        resource[:maxrepositorysize] = '5'
        resource[:expansionpolicy] = 'manual'
        resource[:defaultmapping] = :true
        resource[:cachereadahead] = :true
        resource[:repositorysize] = '10'
        expect(@transport).to receive(:storage_pool_id).with(resource[:storagesystem], resource[:storagepool]) { 'poolId' }
      end
      it_behaves_like 'a method with error handling', :create_thin_volume, :create
      it 'should be able to create it' do
        expect(@transport).to receive(:create_thin_volume).with('storagesystem',
                                                                :poolId => 'poolId',
                                                                :name => resource[:name],
                                                                :sizeUnit => resource[:sizeunit],
                                                                :virtualSize => resource[:size],
                                                                :maximumRepositorySize => resource[:maxrepositorysize],
                                                                :expansionPolicy => resource[:expansionpolicy],
                                                                :createDefaultMapping => resource[:defaultmapping],
                                                                :cacheReadAhead => resource[:cachereadahead],
                                                                :repositorySize => resource[:repositorysize],
                                                                :dataAssuranceEnabled => resource[:dataassurance])
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
      it 'should be able to create it with extra params' do
        resource[:growthalertthreshold] = '100'
        resource[:owningcontrollerid] = 'controllerId'
        expect(@transport).to receive(:create_thin_volume).with('storagesystem',
                                                                :poolId => 'poolId',
                                                                :name => resource[:name],
                                                                :sizeUnit => resource[:sizeunit],
                                                                :virtualSize => resource[:size],
                                                                :maximumRepositorySize => resource[:maxrepositorysize],
                                                                :expansionPolicy => resource[:expansionpolicy],
                                                                :createDefaultMapping => resource[:defaultmapping],
                                                                :cacheReadAhead => resource[:cachereadahead],
                                                                :repositorySize => resource[:repositorysize],
                                                                :dataAssuranceEnabled => resource[:dataassurance],
                                                                :growthAlertThreshold => resource[:growthalertthreshold],
                                                                :owningControllerId => resource[:owningcontrollerid])
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
  end

  describe 'when destroying a volume' do
    it_behaves_like 'a method with error handling', :delete_volume, :destroy
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_volume).with('storagesystem', 'volume-id')
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.set(:id => 'volume-id')
      resource.provider.destroy
    end
  end
  describe 'when destroying a thin volume' do
    before :each do
      resource[:thin] = true
    end
    it_behaves_like 'a method with error handling', :delete_thin_volume, :destroy
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_thin_volume).with('storagesystem', 'thin-volume-id')
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.set(:id => 'thin-volume-id')
      resource.provider.destroy
    end
  end
end
