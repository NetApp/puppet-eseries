require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'
require 'rspec/expectations'

describe Puppet::Type.type(:netapp_e_flash_cache).provider(:netapp_e_flash_cache) do
  before :each do
    Puppet::Type.type(:netapp_e_flash_cache).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_flash_cache).new(
        :name => 'ResourceName',
        :storagesystem => 'ssid116117',
        :cachename => 'cachename',
        :diskids =>  [ "010000005001E8200002D1A80000000000000000"],
        :enableexistingvolumes => false
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName'
    )
  end

  context 'when trying to create flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      request_body = {:driveRefs =>  resource[:diskids], :cacheType => "readOnlyCache", :name => resource[:cachename],:enableExistingVolumes => resource[:enableexistingvolumes]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:is_flash_cache_exist).with(resource[:storagesystem]) { false }
      
      expect(@transport).to receive(:get_drives).with(resource[:storagesystem]) {[{'driveRef' => "010000005001E8200002D1A80000000000000000", 'driveMediaType'=>"ssd"}]}
      
      expect(@transport).to receive(:create_flash_cache).with(resource[:storagesystem],request_body) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to delete flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      resource[:name]='cachename'
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:is_flash_cache_exist).with(resource[:storagesystem]) {  {'name' => 'cachename' } }

      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) {  {'name' => 'cachename' }  }

      expect(@transport).to receive(:delete_flash_cache).with(resource[:storagesystem]) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.delete
    end
  end

  context 'when trying to update flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      resource[:configtype]='database'
      resource[:newname]='cachename1'
      request_body = {:name => resource[:newname], :configType => resource[:configtype]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) {  {'name' => 'cachename', 'flashCacheBase' => { 'status' => 'optimal' } } }

      expect(@transport).to receive(:update_flash_cache).with(resource[:storagesystem], request_body) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.update
    end
  end

  context 'when trying to resume flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) { {'name' => 'cachename', 'flashCacheBase' => { 'status' => 'suspended' } }  }

      expect(@transport).to receive(:resume_flash_cache).with(resource[:storagesystem] ) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.resume
    end
  end

  context 'when trying to suspend flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) { {'name' => 'cachename', 'flashCacheBase' => { 'status' => 'optimal' } } }

      expect(@transport).to receive(:suspend_flash_cache).with(resource[:storagesystem] ) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.suspend
    end
  end

  context 'when trying to check validity of drives' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_drives).with(resource[:storagesystem]) {[{'driveRef' => "010000005001E8200002D1A80000000000000000", 'driveMediaType'=>"ssd"}]}
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.check_drives_validity
    end
  end
  
end
