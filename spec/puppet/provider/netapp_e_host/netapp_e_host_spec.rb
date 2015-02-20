require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_host).provider(:netapp_e_host) do
  before :each do
    Puppet::Type.type(:netapp_e_host).stubs(:defaultprovider).returns described_class
    @transport = double
    allow(@transport).to receive(:host_group_id).and_raise(RuntimeError)
  end

  let :resource do
    Puppet::Type.type(:netapp_e_host).new(:name => 'name',
                                          :storagesystem => 'storagesystem',
                                          :typeindex => '4',
                                          :groupid => 'groupid',
                                          :ports => [{ 'address' => '', 'label' => '', 'type' => 'IOInterfaceType' }],
                                          :ensure => :present)
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
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
    it_behaves_like 'a method with error handling', :get_hosts, :instances
    it 'should return an array of current hosts entries' do
      expect(@transport).to receive(:get_hosts) { JSON.parse(File.read(my_fixture('hosts-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(1)
      instances.map do |prov|
        { :name => prov.get(:name),
          :id => prov.get(:id),
          :storagesystem => prov.get(:storagesystem),
          :typeindex => prov.get(:typeindex),
          :groupid => prov.get(:groupid),
          :ports => prov.get(:ports),
          :initiators => prov.get(:initiators),
          :ensure => prov.get(:ensure)
        }
      end.should == [{ :name => resource[:name],
                       :id => 'id',
                       :storagesystem => resource[:storagesystem],
                       :typeindex => resource[:typeindex],
                       :groupid => resource[:groupid],
                       :ports => resource[:ports],
                       :initiators => 'inititators',
                       :ensure => resource[:ensure]
                     }]
    end
  end

  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_hosts) { JSON.parse(File.read(my_fixture('hosts-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      current_provider = resource.provider
      resources = { 'name' => resource }
      described_class.prefetch(resources)
      expect(resources['name']).not_to be(current_provider)
    end
  end

  describe 'when creating a resource' do
    it_behaves_like 'a method with error handling', :create_host, :create
    it 'should be able to create it' do
      expect(@transport).to receive(:create_host).with(resource[:storagesystem],
                                                       :name => resource[:name],
                                                       'ports' => resource[:ports],
                                                       'groupId' => resource[:groupid],
                                                       :hostType => { :index => resource[:typeindex]
                                                       })
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
    it 'should be able to create it when groupid is Hash' do
      resource[:groupid] = { :value => 'groupid' }
      expect(resource.provider).to receive(:transport) do
        allow(@transport).to receive(:host_group_id).with(resource[:storagesystem], resource[:groupid][:value]) { 'group' }
        @transport
      end
      expect(@transport).to receive(:create_host).with(resource[:storagesystem],
                                                       :name => resource[:name],
                                                       'ports' => resource[:ports],
                                                       'groupId' => 'group',
                                                       :hostType => { :index => resource[:typeindex]
                                                       })
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
    it 'should not be able to create if did not found group id' do
      resource[:groupid] = { :value => 'groupid' }
      expect(resource.provider).to receive(:transport) do
        allow(@transport).to receive(:host_group_id).with(resource[:storagesystem], resource[:groupid][:value])
        @transport
      end
      expect { resource.provider.create }.to raise_error(Puppet::Error)
    end
  end

  describe 'when destroying a resource' do
    it_behaves_like 'a method with error handling', :delete_host, :destroy
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_host).with(resource[:storagesystem], 'id')
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.set(:id => 'id')
      resource.provider.destroy
    end
  end
  describe 'when modifying a resource' do
    context 'and error occurs' do
      before :each do
        resource.provider.typeindex = '4'
      end
      it_behaves_like 'a method with error handling', :update_host, :flush
    end
    context 'should be able to modify an existing resource' do
      before :each do
        resource.provider.set(:id => 'id')
      end
      it 'if groupid changes' do
        resource.provider.groupid = 'new_group_id'
        expect(@transport).to receive(:update_host).with(resource[:storagesystem], 'id',
                                                         :groupId => 'new_group_id')
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.flush
      end
      context 'when groupid in resource is a hash' do
        before :each do
          resource[:groupid] = { :value => 'groupid' }
        end
        it 'if groupid changes' do
          expect(@transport).to receive(:host_group_id).with(resource[:storagesystem],
                                                             resource[:groupid][:value]) { 'name_of_new_group' }
          expect(@transport).to receive(:update_host).with(resource[:storagesystem], 'id',
                                                           :groupId => 'name_of_new_group')
          allow(resource.provider).to receive(:transport) { @transport }
          resource.provider.groupid = 'new_group_id'
          resource.provider.flush
        end

        it 'if groupid changes and transport.host_group_id will not return anything' do
          expect(@transport).to receive(:host_group_id) { nil }
          allow(resource.provider).to receive(:transport) { @transport }
          expect { resource.provider.groupid = 'new_group_id' }.to raise_error(Puppet::Error)
        end

        it 'if groupid changes and host_group_id raises error' do
          resource[:groupid] = { :value => 'groupid' }
          expect(@transport).to receive(:host_group_id).and_raise(Puppet::Error, 'puppet_error')
          allow(resource.provider).to receive(:transport) { @transport }
          expect { resource.provider.groupid = 'new_group_id' }.to raise_error(Puppet::Error)
        end
      end
      it 'if typeindex changes' do
        resource.provider.typeindex = '7'
        expect(@transport).to receive(:update_host).with(resource[:storagesystem], 'id',
                                                         :hostType => { :index => '4' })
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.flush
      end
      it 'if typeindex changes' do
        resource.provider.ports = 'ports'
        expect(@transport).to receive(:update_host).with(resource[:storagesystem], 'id',
                                                         :ports => [{ 'label' => '',
                                                                      'type' => 'IOInterfaceType',
                                                                      'address' => '' }],
                                                         :portsToRemove => nil)
        allow(resource.provider).to receive(:transport) { @transport }
        resource.provider.flush
      end
    end
  end
end
