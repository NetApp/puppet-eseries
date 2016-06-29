require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_consistency_multiple_members).provider(:netapp_e_consistency_multiple_members) do
  before :each do
    Puppet::Type.type(:netapp_e_consistency_multiple_members).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_consistency_multiple_members).new(
        :name => 'ResourceName',
        :storagesystem => 'ssid116117',
        :consistencygroup => 'CGname',
        :volumes => [{ 'volume' => 'Volume-1', 'scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'}]
    )
  end

  let :provider do
    described_class.new(
        :name => 'ResourceName',
    )
  end
  context 'when adding volumes to consistency group' do
    context 'with only mandatory parameters' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1'},{ 'volume' => 'Volume-2'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1', 'volumeId' => '123'},{ 'volume' => 'Volume-2', 'volumeId' => '456'}]

        expect(@transport).to receive(:get_consistency_group_members) { [{'baseVolumeName' => 'VnameNotMatching', 'id' => '123560'},
                                                                      { 'baseVolumeName' => 'VnameAnother', 'id' => '12389'}] }

        resource[:volumes].each do |curvol|
          expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => curvol['volumeId']
                              )
        end

        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.addvolumes
      end
    end
    context 'with optional parameters except storage pool' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1', 'scanmedia' => true},{ 'volume' => 'Volume-2','scanmedia' => true}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','scanmedia' => true, 'volumeId' => '123'},{ 'volume' => 'Volume-2','scanmedia' => true, 'volumeId' => '456'}]

        expect(@transport).to receive(:get_consistency_group_members) { [{'baseVolumeName' => 'VnameNotMatching', 'id' => '123560'},
                                                                      { 'baseVolumeName' => 'VnameAnother', 'id' => '12389'}] }

        resource[:volumes].each do |curvol|
          expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => curvol['volumeId'],
                                                                      :scanMedia => curvol['scanmedia']
                              )
        end

        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.addvolumes

      end
    end
    context 'with optional parameters with storage pool' do
      # it_behaves_like 'a method with error handling', :add_consistency_group_member, :create
      it 'should be able to add it if storage pool is valid' do


        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1', 'scanmedia' => true,'repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','scanmedia' => true,'repositorypool' => 'Disk_Pool_1'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','scanmedia' => true,'repositorypool' => 'Disk_Pool_1', 'volumeId' => '123'},{ 'volume' => 'Volume-2','scanmedia' => true,'repositorypool' => 'Disk_Pool_1', 'volumeId' => '456'}]

        expect(@transport).to receive(:get_consistency_group_members) { [{'baseVolumeName' => 'VnameNotMatching', 'id' => '123560'},
                                                                      { 'baseVolumeName' => 'VnameAnother', 'id' => '12389'}] }

        resource[:volumes].each do |curvol|
          expect(@transport).to receive(:add_consistency_group_member).with(resource[:storagesystem],
                                                                      '123456',
                                                                      :volumeId => curvol['volumeId'],
                                                                      :scanMedia => curvol['scanmedia'],
                                                                      :repositoryPoolId => 'sp123456'
                              )
        end

        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.addvolumes
      end
      it 'should be raise error if consistency group is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource[:consistencygroup] = 'CGnameNotMatching'

        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
      it 'should be raise error if scanmedia is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1', 'scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','scanmedia' => 'invalid','repositorypool' => 'Disk_Pool_1'}]


        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
      it 'should be raise error if validateparity is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1', 'validateparity' => 'invalid','repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','validateparity' => 'invalid','repositorypool' => 'Disk_Pool_1'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','validateparity' => 'invalid','repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','validateparity' => 'invalid','repositorypool' => 'Disk_Pool_1'}]


        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
      it 'should be raise error if repositorypercent is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1', 'repositorypercent' => -1,'repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','repositorypercent' => 101,'repositorypool' => 'Disk_Pool_1'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','repositorypercent' => -1,'repositorypool' => 'Disk_Pool_1'},{ 'volume' => 'Volume-2','repositorypercent' => 101,'repositorypool' => 'Disk_Pool_1'}]


        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
      it 'should be raise error if volume is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1-Notmatching'},{ 'volume' => 'Volume-2'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1-Notmatching'},{ 'volume' => 'Volume-2'}]


        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
      it 'should be raise error if storage pool is invalid' do

        expect(@transport).to receive(:get_consistency_groups) {[{"creationPendingStatus" => "PITCreationPendingStatus",
                                                                      "name" => "CGname",
                                                                      "id" => "123456",
                                                                      "storagesystem" => "ssid116117",
                                                                      "cgRef" => "123456",
                                                                      "label" => "CGname"}]}
        resource.provider.set(:consistencyid => '123456')
        resource[:consistencyid] = '123456'

        expect(@transport).to receive(:get_volumes) { [{'label' => 'Volume-1', 'id' => '123'},{'label' => 'Volume-2', 'id' => '456'}] }
        
        expect(@transport).to receive(:get_storage_pools) { [{'label' =>'Disk_Pool_1', 
                                                            'storagesystem' => 'ssid116117',
                                                            'id' => 'sp123456'}] }
        resource.provider.set(:volumes => [{ 'volume' => 'Volume-1','repositorypool' => 'Disk_Pool_1-NotMatching'},{ 'volume' => 'Volume-2','repositorypool' => 'Disk_Pool_1'}])

        resource[:volumes] = [{ 'volume' => 'Volume-1','repositorypool' => 'Disk_Pool_1-NotMatching'},{ 'volume' => 'Volume-2','repositorypool' => 'Disk_Pool_1'}]


        allow(resource.provider).to receive(:transport) { @transport }
        expect { resource.provider.addvolumes }.to raise_error(Puppet::Error)
      end
    end
  end
end
