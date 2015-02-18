require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_storage_system).provider(:netapp_e_storage_system) do
  before :each do
    Puppet::Type.type(:netapp_e_storage_system).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_storage_system).new(
        :name => 'name',
        :ensure => :present,
        :controllers => %w(10.250.117.116 10.250.117.117),
        :meta_tags => [{ 'key' => 'poweron', 'valueList' => ['true'] },
                       { 'key' => 'u89', 'valueList' => %w(11 aab) }],
        :password => 'password'

    )
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
    it_behaves_like 'a method with error handling', :get_storage_systems, :instances
    it 'should return an array of current storage_system entries' do
      expect(@transport).to receive(:get_storage_systems) { JSON.parse(File.read(my_fixture('storage_system-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      instances = described_class.instances
      instances.size.should eq(1)
      instances.map do |prov|
        { :name => prov.get(:name),
          :ensure => prov.get(:ensure),
          :controllers => prov.get(:controllers),
          :meta_tags => prov.get(:meta_tags),
          :wwn => prov.get(:wwn)
        }
      end.should == [{ :name => resource[:name],
                       :ensure => resource[:ensure],
                       :controllers => resource[:controllers],
                       :meta_tags => resource[:meta_tags],
                       :wwn => 'wwn' }]
    end
  end

  describe '#prefetch' do
    it 'exists' do
      expect(@transport).to receive(:get_storage_systems) { JSON.parse(File.read(my_fixture('storage_system-list.json'))) }
      allow(described_class).to receive(:transport) { @transport }
      current_provider = resource.provider
      resources = { 'name' => resource }
      described_class.prefetch(resources)
      expect(resources['name']).not_to be(current_provider)
    end
  end

  describe 'when creating a resource' do
    it_behaves_like 'a method with error handling', :create_storage_system, :create
    it 'should be able to create it' do
      expect(@transport).to receive(:create_storage_system).with(:id => resource[:name],
                                                                 :controllerAddresses => resource[:controllers],
                                                                 :metaTags => resource[:meta_tags],
                                                                 :password => resource[:password]
                            )
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.create
    end
  end

  describe 'when destroying a resource' do
    before :each do
      resource.provider.destroy
    end
    it_behaves_like 'a method with error handling', :delete_storage_system, :flush
    it 'should be able to delete it' do
      expect(@transport).to receive(:delete_storage_system).with(resource[:name])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.flush
    end
  end

  describe 'when modifying a resource' do
    before :each do
      resource.provider.meta_tags = resource[:meta_tags]
    end
    it_behaves_like 'a method with error handling', :update_storage_system, :flush
    it 'should be able to modify an existing resource' do
      # Need to have a resource present that we can modify
      resource.provider.set(:name => resource[:name])
      expect(@transport).to receive(:update_storage_system).with(resource[:name], :metaTags => resource[:meta_tags])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.flush
    end
  end
end
