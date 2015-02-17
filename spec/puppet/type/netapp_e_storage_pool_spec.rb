require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_storage_pool) do
  before :each do
    @netapp_e_storage_pool = { :name => 'netapp_e_storage_pool',
                               :storagesystem => 'storagesystem',
                               :diskids => 'diskids',
                               :raidlevel => :raidUnsupported }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_storage_pool
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :diskids, :storagesystem, :erasedrives].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:id, :raidlevel, :ensure].each do |prop|
      it "should have a #{prop} property" do
        resource[:id] = 'id'
        described_class.attrtype(prop).should == :property
      end
    end
    [:storagesystem, :name, :diskids, :raidlevel].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect {described_class.new(resource)}.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name, true
    end
    context 'for diskids' do
      it_behaves_like 'a string param/property', :diskids, true
      it_behaves_like 'a array_matching param', :diskids, 'val', %w(val1 val2)
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for id' do
      it_behaves_like 'a string param/property', :id, true
    end
    context 'for erasedrives' do
      it_behaves_like 'a boolish param/property', :erasedrives, false
    end
    context 'for raidlevel' do
      it_behaves_like 'a enum param/property', :raidlevel, %w(raidUnsupported raidAll raid0 raid1 raid3 raid5 raid6 raidDiskPool __UNDEFINED)
    end
  end
end
