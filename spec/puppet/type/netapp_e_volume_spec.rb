require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_volume) do
  before :each do
    @volume = { :name => 'volume' }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @volume
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:storagesystem, :storagepool, :sizeunit, :size, :segsize, :dataassurance, :thin, :repositorysize, :maxrepositorysize,
     :owningcontrollerid, :growthalertthreshold, :defaultmapping, :expansionpolicy, :cachereadahead].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:id, :poolid, :ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name, true
    end
    context 'for id' do
      it_behaves_like 'a string param/property', :id, true
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for storagepool' do
      it_behaves_like 'a string param/property', :storagepool, true
    end
    context 'for poolid' do
      it_behaves_like 'a string param/property', :poolid, true
    end
    context 'for sizeunit' do
      it_behaves_like 'a enum param/property', :sizeunit, %w(bytes b kb mb gb tb pb eb zb yb)
    end
    context 'for size' do
      it_behaves_like 'a string param/property', :size, true
    end
    context 'for segsize' do
      it_behaves_like 'a string param/property', :segsize, true
    end
    context 'for dataassurance' do
      it_behaves_like 'a boolish param/property', :dataassurance, :false
    end
    context 'for thin' do
      it_behaves_like 'a boolish param/property', :thin, :false
    end
    context 'for repositorysize' do
      it_behaves_like 'a string param/property', :repositorysize, true
    end
    context 'for maxrepositorysize' do
      it_behaves_like 'a string param/property', :maxrepositorysize, true
    end
    context 'for owningcontrollerid' do
      it_behaves_like 'a string param/property', :owningcontrollerid, true
    end
    context 'for growthalertthreshold' do
      it_behaves_like 'a string param/property', :growthalertthreshold, true
    end
    context 'for defaultmapping' do
      it_behaves_like 'a boolish param/property', :defaultmapping, :false
    end
    context 'for expansionpolicy' do
      it_behaves_like 'a enum param/property', :expansionpolicy, %w(unknown manual automatic __UNDEFINED), 'automatic'
    end
    context 'for cachereadahead' do
      it_behaves_like 'a boolish param/property', :cachereadahead, :false
    end
  end
end
