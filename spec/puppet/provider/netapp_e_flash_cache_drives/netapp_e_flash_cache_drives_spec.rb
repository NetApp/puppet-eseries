require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'
require 'rspec/expectations'

describe Puppet::Type.type(:netapp_e_flash_cache_drives).provider(:netapp_e_flash_cache_drives) do
  before :each do
    Puppet::Type.type(:netapp_e_flash_cache_drives).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_flash_cache_drives).new(
        :name => 'ResourceName',
        :storagesystem => 'ssid116117',
        :cachename => 'cachename',
        :diskids =>  [ "010000005001E8200002D1A80000000000000000"],
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName'
    )
  end

  context 'when trying to check validity of drives' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_drives).with(resource[:storagesystem]) {[{'driveRef' => "010000005001E8200002D1A80000000000000000", 'driveMediaType'=>"ssd"}]}
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.check_drives_validity
    end
  end

  context 'when trying to add drives to flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      request_body = {:driveRef =>  resource[:diskids]}
      resource[:name]='cachename'
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) {  {'name' => 'cachename', 'flashCacheBase' => { 'status' => 'optimal' } ,'driveRefs' => ["010000005001E8200002D1A80000000000000001"]} }

      expect(@transport).to receive(:get_drives).with(resource[:storagesystem]) {[{'driveRef' => "010000005001E8200002D1A80000000000000000", 'driveMediaType'=>"ssd"}]}

      expect(@transport).to receive(:flash_cache_add_drives).with(resource[:storagesystem], request_body) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.add
    end
  end

  context 'when trying to remove drives to flash cache' do
    it 'should be able to do it with only mandatory valid parameters' do
      request_body = {:driveRef =>  resource[:diskids]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { [{'id' => 'ssid116117' }] }
      
      expect(@transport).to receive(:get_flash_cache).with(resource[:storagesystem]) {  {'name' => 'cachename', 'flashCacheBase' => { 'status' => 'optimal' } ,'driveRefs' => ["010000005001E8200002D1A80000000000000001","010000005001E8200002D1A80000000000000000"]} }

      expect(@transport).to receive(:get_drives).with(resource[:storagesystem]) {[{'driveRef' => "010000005001E8200002D1A80000000000000000", 'driveMediaType'=>"ssd"}]}

      expect(@transport).to receive(:flash_cache_remove_drives).with(resource[:storagesystem], request_body) {true}
        
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.remove
    end
  end
  
end
