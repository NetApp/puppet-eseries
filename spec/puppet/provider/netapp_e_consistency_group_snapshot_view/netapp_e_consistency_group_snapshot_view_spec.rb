require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'
require 'rspec/expectations'

describe Puppet::Type.type(:netapp_e_consistency_group_snapshot_view).provider(:netapp_e_consistency_group_snapshot_view) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_group_snapshot_view).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_group_snapshot_view).new(
        :name => 'ResourceName',
        :viewname => 'v1',
        :snapshotnumber => 123,
        :validateparity => false,
        :storagesystem => 'ssid116117',
        :consistencygroup => 'Create_CG1',
        :ensure => :absent
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName'
    )
  end

  describe 'when asking if snapshot exists?' do
    it 'should return :present if snapshot is present' do
      resource[:ensure] = :absent
      expect(resource.provider.exists?).to eq(true)
    end
    it 'should return :absent if snapshot is absent' do
      resource[:ensure] = :present
      expect(resource.provider.exists?).to eq(false)
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot' do
      resource[:accessmode] = 'readWrite'
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber],:accessMode => resource[:accessmode]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot and accessmode is not set' do
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber],:accessMode => resource[:accessmode]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot and scanmedia is not set' do
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber],:accessMode => resource[:accessmode]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot and repositorypercent is not set' do
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber],:accessMode => resource[:accessmode]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot and scanmedia is set' do
      resource[:scanmedia] = true
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber],:accessMode => resource[:accessmode], :scanMedia => resource[:scanmedia]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is bySnapshot and repositorypercent is set' do
      resource[:repositorypercent] = 70
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :pitSequenceNumber => resource[:snapshotnumber], :accessMode => resource[:accessmode]}
      request_body[:repositoryPercent] = resource[:repositorypercent]
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it when view type is byVolume' do
      resource[:viewtype] = 'byVolume'
      resource[:volume] = 'Volume1'
      request_body = {:name =>  resource[:viewname], :validateParity => resource[:validateparity], :accessMode => resource[:accessmode]}
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem], '123456', resource[:snapshotnumber] ) {['pitSequenceNumber' => '1']}
      expect(@transport).to receive(:get_volume_id).with(resource[:storagesystem], resource[:volume] ) { '123456789' }
      expect(@transport).to receive(:get_pit_id_by_volume_id).with(resource[:storagesystem], '123456', resource[:snapshotnumber],  '123456789' ) { '111156789' }
      request_body[:pitId] = '111156789' 
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname] ) { false }
      expect(@transport).to receive(:create_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',request_body) { true }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to destroy snapshot' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_consistency_group_snapshot_view_id).with(resource[:storagesystem], '123456', resource[:viewname]) { 123 }
      expect(@transport).to receive(:delete_consistency_group_snapshot_view).with(resource[:storagesystem],'123456',123) {true}
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.destroy
    end
  end

end
