require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_consistency_members).provider(:netapp_e_consistency_members) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_members).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_members).new(
        :name => 'ResourceName',
        :volume => 'Vname',
        :storagesystem => 'ssid116117',
        :consistencygroup => 'CGname',
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName',
    )
  end

describe 'when asking if consistency group member exist?' do
    # it_behaves_like 'a method with error handling', :get_consistency_groups, :exist?
    it 'should return :present if consistency group member is present' do

      expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}



      expect(@transport).to receive(:get_volumes) { [{'label' => 'Vname', 'id' => '123'}] }


      expect(@transport).to receive(:get_consistency_group_members) { [{'baseVolumeName' => 'Vname', 'id' => '123'},
                                                                      { 'baseVolumeName' => 'VnameAnother', 'id' => '12389'}] }

      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exist?).to eq(:present)
    end
    it 'should return :absent if consistency group member is absent' do

      expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}


      expect(@transport).to receive(:get_volumes) { [{'label' => 'Vname', 'id' => '123'}] }

      expect(@transport).to receive(:get_consistency_group_members) { [{'baseVolumeName' => 'VnameNotMatching', 'id' => '123560'},
                                                                      { 'baseVolumeName' => 'VnameAnother', 'id' => '12389'}] }

      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exist?).to eq(:absent)
    end
    it 'should return absent when specified volume does not exist in storage system' do

      expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}


      expect(@transport).to receive(:get_volumes) { [{'label' => 'VnameNotMatching', 'id' => '123560'}] }

      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exist?).to eq(:absent)
    end
  end

  context 'when adding volume to consistency group' do
    context 'with only mandatory parameters' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'

        expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => '123'
                              )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with optional parameters except storage pool' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'
        resource[:scanmedia] = true
        resource[:validateparity] = true
        resource[:repositorypercent] = 32

        expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => '123',
                                                                      :scanMedia => resource[:scanmedia],
                                                                      :validateParity => resource[:validateparity],
                                                                      :repositoryPercent => resource[:repositorypercent]
                               )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
    end
    context 'with optional parameters with storage pool' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it if storage pool is valid' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'
        resource[:scanmedia] = true
        resource[:validateparity] = true
        resource[:repositorypercent] = 32
        resource[:repositorypool] = 'SPool'

        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'SPool', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }


        expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => '123',
                                                                      :scanMedia => resource[:scanmedia],
                                                                      :validateParity => resource[:validateparity],
                                                                      :repositoryPercent => resource[:repositorypercent],
                                                                      :repositoryPoolId => 'sp123456'
                               )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.create
      end
      it 'should be raise error if storage pool is invalid' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'
        resource[:scanmedia] = true
        resource[:validateparity] = true
        resource[:repositorypercent] = 32
        resource[:repositorypool] = 'SPool123'

        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'SPool', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }

        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.create }.to raise_error(Puppet::Error)
      end
    end
  end

  context 'when removing volume from consistency group' do
    context 'with retain repositories true' do
      # it_behaves_like 'a method with error handling', :remove_consistency_group_member, :destroy
      it 'should be able to remove it' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'
        resource[:retainrepositories] = true

        expect(@transport).to receive(:remove_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      '123',
                                                                      resource[:retainrepositories]
                               )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.destroy
      end
    end
    context 'with retain repositories false' do
      # it_behaves_like 'a method with error handling', :remove_consistency_group_member, :destroy
      it 'should be able to remove it' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'
        resource[:retainrepositories] = false

        expect(@transport).to receive(:remove_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      '123',
                                                                      resource[:retainrepositories]
                               )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.destroy
      end
    end
    context 'without passing retain repositories' do
      # it_behaves_like 'a method with error handling', :remove_consistency_group_member, :destroy
      it 'should be able to remove it' do

        resource.provider.set(:consistencyid => '123456')
        resource.provider.set(:volumeid => '123')

        resource[:consistencyid] = '123456'
        resource[:volumeid] = '123'

        expect(@transport).to receive(:remove_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      '123',
                                                                      false
                               )
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.destroy
      end
    end
  end
end
