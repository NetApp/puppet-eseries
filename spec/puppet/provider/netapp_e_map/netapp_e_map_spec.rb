require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_map).provider(:netapp_e_map) do
  before :each do
    Puppet::Type.type(:netapp_e_map).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_map).new(
        :name => 'name',
        :storagesystem => 'storagesystem',
        :source => 'source',
        :target => 'target',
        :lun => 'lun'

    )
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
  end

  describe 'when creating a resource' do
    it 'should raise Puppet::Error when get_volumes raised error' do
      expect(@transport).to receive(:get_volumes).and_raise('some message')

      allow(resource.provider).to receive(:transport) { @transport }
      expect do
        resource.provider.create(resource[:storagesystem],
                                 resource[:source],
                                 resource[:target],
                                 resource[:type],
                                 resource[:lun])
      end.to raise_error(Puppet::Error, 'some message')
    end
    it 'should raise Puppet::Error when host_group_id raised error' do
      expect(@transport).to receive(:get_volumes) { [] }
      expect(@transport).to receive(:host_group_id).and_raise('some message')

      allow(resource.provider).to receive(:transport) { @transport }
      expect do
        resource.provider.create(resource[:storagesystem],
                                 resource[:source],
                                 resource[:target],
                                 resource[:type],
                                 resource[:lun])
      end.to raise_error(Puppet::Error, 'some message')
    end

    it 'should raise Puppet::Error when create_lun_mapping raised error' do
      expect(@transport).to receive(:get_volumes) { [] }
      expect(@transport).to receive(:host_group_id).with(resource[:storagesystem],
                                                         resource[:target]) { 'host_group_id' }
      expect(@transport).to receive(:create_lun_mapping).and_raise('some message')

      allow(resource.provider).to receive(:transport) { @transport }
      expect do
        resource.provider.create(resource[:storagesystem],
                                 resource[:source],
                                 resource[:target],
                                 resource[:type],
                                 resource[:lun])
      end.to raise_error(Puppet::Error, 'some message')
    end

    it 'should be able to create for target hostgroup' do
      expect(@transport).to receive(:get_volumes) { [] }
      expect(@transport).to receive(:host_group_id).with(resource[:storagesystem],
                                                         resource[:target]) { 'host_group_id' }
      expect(@transport).to receive(:create_lun_mapping).with(resource[:storagesystem],
                                                              :lun => resource['lun'],
                                                              :mappableObjectId => false,
                                                              :targetId => 'host_group_id')

      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create(resource[:storagesystem],
                               resource[:source],
                               resource[:target],
                               resource[:type],
                               resource[:lun])
    end
    it 'should be able to create for target host' do
      resource[:type] = :host
      expect(@transport).to receive(:get_volumes) { [] }
      expect(@transport).to receive(:host_id).with(resource[:storagesystem],
                                                   resource[:target]) { 'host_id' }
      expect(@transport).to receive(:create_lun_mapping).with(resource[:storagesystem],
                                                              :lun => resource['lun'],
                                                              :mappableObjectId => false,
                                                              :targetId => 'host_id')

      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create(resource[:storagesystem],
                               resource[:source],
                               resource[:target],
                               resource[:type],
                               resource[:lun])
    end
    it 'should be able to create it with volumes' do
      resource[:type] = :host
      expect(@transport).to receive(:get_volumes) do
        [{ 'label' => 'wrong_label',
           'storagesystem' => 'wrong_storagesystem',
           'id' => 'id1' },
         { 'label' => resource[:source],
           'storagesystem' => resource[:storagesystem],
           'id' => 'id2' },
         { 'label' => 'wrong_label',
           'storagesystem' => resource[:storagesystem],
           'id' => 'id3' },
         { 'label' => resource[:source],
           'storagesystem' => 'wrong_storagesystem',
           'id' => 'id4' }
        ]
      end
      expect(@transport).to receive(:host_id).with(resource[:storagesystem],
                                                   resource[:target]) { 'host_id' }
      expect(@transport).to receive(:create_lun_mapping).with(resource[:storagesystem],
                                                              :lun => resource['lun'],
                                                              :mappableObjectId => 'id2',
                                                              :targetId => 'host_id')

      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create(resource[:storagesystem],
                               resource[:source],
                               resource[:target],
                               resource[:type],
                               resource[:lun])
    end
  end
  describe 'when destroying a resource' do
    it 'should raise Puppet::Error when delete_lun_mapping raised error' do
      expect(@transport).to receive(:get_lun_mapping).with(resource[:storagesystem],
                                                           resource[:lun],
                                                           false) { 'map_id' }
      expect(@transport).to receive(:delete_lun_mapping).and_raise('some message')
      allow(resource.provider).to receive(:transport) { @transport }
      expect { resource.provider.destroy resource[:storagesystem], resource[:lun] }.to raise_error(Puppet::Error, 'some message')
    end
    it 'should raise Puppet::Error when get_lun_mapping raised error' do
      expect(@transport).to receive(:get_lun_mapping).and_raise('some message')
      allow(resource.provider).to receive(:transport) { @transport }
      expect { resource.provider.destroy resource[:storagesystem], resource[:lun] }.to raise_error(Puppet::Error, 'some message')
    end
    it 'should be able to delete it' do
      expect(@transport).to receive(:get_lun_mapping).with(resource[:storagesystem],
                                                           resource[:lun],
                                                           false) { 'map_id' }
      expect(@transport).to receive(:delete_lun_mapping).with(resource[:storagesystem],
                                                              'map_id')
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.destroy resource[:storagesystem], resource[:lun]
    end
  end
end
