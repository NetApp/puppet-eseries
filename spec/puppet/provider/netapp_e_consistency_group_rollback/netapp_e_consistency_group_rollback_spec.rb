require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'
require 'rspec/expectations'

describe Puppet::Type.type(:netapp_e_consistency_group_rollback).provider(:netapp_e_consistency_group_rollback) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_group_rollback).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_group_rollback).new(
        :name => 'ResourceName',
        :storagesystem => 'ssid116117',
        :consistencygroup => 'Create_CG1',
        :snapshotnumber => 123
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName'
    )
  end

  context 'when trying to rollback consistency group' do
    it 'should be able to do it with only mandatory valid parameters' do
      
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      
      expect(@transport).to receive(:get_consistency_group_snapshots_by_seqno).with(resource[:storagesystem],'123456', resource[:snapshotnumber]) { [{'pitSequenceNumber' => 1}] }
      
      expect(@transport).to receive(:rollback_consistency_group).with(resource[:storagesystem],'123456',resource[:snapshotnumber]) {true}
      
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.rollback
    end

  end
  
end
