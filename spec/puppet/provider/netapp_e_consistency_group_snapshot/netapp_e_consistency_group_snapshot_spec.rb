require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'
require 'rspec/expectations'

describe Puppet::Type.type(:netapp_e_consistency_group_snapshot).provider(:netapp_e_consistency_group_snapshot) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_group_snapshot).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_group_snapshot).new(
        :name => 'ResourceName',
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

  describe 'when asking if snapshot exist?' do
    it 'should return :present if snapshot is present' do
      resource[:ensure] = :absent
      expect(resource.provider.exists?).to eq(:present)
    end
    it 'should return :absent if snapshot is absent' do
      resource[:ensure] = :present
      expect(resource.provider.exists?).to eq(:absent)
    end
  end

  context 'when trying to create snapshot' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:create_consistency_group_snapshot).with(resource[:storagesystem],'123456',{}) {[{'pitSequenceNumber' => '1' }]}
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  context 'when trying to destroy snapshot' do
    it 'should be able to do it with only mandatory valid parameters' do
      expect(@transport).to receive(:get_storage_system).with(resource[:storagesystem]) { 'ssid116117' }
      expect(@transport).to receive(:get_consistency_group_id).with(resource[:storagesystem], resource[:consistencygroup]) { '123456' }
      expect(@transport).to receive(:get_oldest_sequence_no).with(resource[:storagesystem], resource[:consistencygroup]) { 123 }
      expect(@transport).to receive(:remove_oldest_consistency_group_snapshot).with(resource[:storagesystem],'123456',123) {true}
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.destroy
    end
  end

end
