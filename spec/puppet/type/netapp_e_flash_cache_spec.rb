require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_flash_cache) do
  before :each do
    @netapp_e_flash_cache = { :name => 'createflashcache',
                           :storagesystem => 'ssid116117',
                           :cachename => 'cachename',
                           :enableexistingvolumes   => false,
                           :diskids                 =>  [ "010000005001E8200002D1A80000000000000000",
                            "010000005001E8200002D20C0000000000000000"],
                            }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_flash_cache
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :storagesystem, :cachename, :diskids, :enableexistingvolumes, :ignorestate, :newname, :configtype].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:name, :storagesystem, :cachename].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for name' do
      it_behaves_like 'a string param/property', :name, true
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for cachename' do
      it_behaves_like 'a string param/property', :cachename
    end
    context 'for enableexistingvolumes' do
      it_behaves_like 'a boolean param', :enableexistingvolumes
    end
    context 'for ignorestate' do
      it_behaves_like 'a boolean param', :ignorestate
    end
    context 'for newname' do
      it_behaves_like 'a string param/property', :newname
    end
    context 'for configtype' do
      it_behaves_like 'a enum param/property', :configtype, ['filesystem', 'database','multimedia']
    end
    context 'for diskids' do
      it_behaves_like 'a array_matching param', :diskids, [
                            "010000005001E8200002D1A80000000000000000",
                            "010000005001E8200002D20C0000000000000000"] , [
                            "010000005001E8200002D1A80000000000000000",
                            "010000005001E8200002D20C0000000000000000"]
    end
  end

  context 'for ensure' do
      it_behaves_like 'a enum param/property', :ensure, %w(created suspended resumed deleted updated), :created
      it 'should set ensure to create when sync and validateparity is set to false' do
        res = described_class.new(resource)
        res[:ensure] = :created
        res[:enableexistingvolumes] = false
        ensure_status = double(:create)

        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to create when sync and validateparity is set to true' do
        res = described_class.new(resource)
        res[:ensure] = :created
        res[:enableexistingvolumes] = true
        ensure_status = double(:create)

        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to delete when sync' do
        res = described_class.new(resource)
        res[:ensure] = :deleted
        ensure_status = double(:delete)
        expect(res.provider).to receive(:delete) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to update when sync and configtype is set to database' do
        res = described_class.new(resource)
        res[:ensure] = :updated
        ensure_status = double(:update)
        res[:configtype] = 'database'
        expect(res.provider).to receive(:update) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to update when sync and newname is set to ssd123' do
        res = described_class.new(resource)
        res[:ensure] = :updated
        ensure_status = double(:update)
        res[:newname] = 'ssd123'
        expect(res.provider).to receive(:update) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to suspend when sync and ignorestate is not set' do
        res = described_class.new(resource)
        res[:ensure] = :suspended
        ensure_status = double(:suspend)
        expect(res.provider).to receive(:suspend) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
        expect(res.parameter(:ignorestate).value).to be false
      end
      it 'should set ensure to suspend when sync and ignorestate is set to true' do
        res = described_class.new(resource)
        res[:ensure] = :suspended
        res[:ignorestate] = :true
        ensure_status = double(:suspend)
        expect(res.provider).to receive(:suspend) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
        expect(res.parameter(:ignorestate).value).to be true
      end
      it 'should set ensure to resume when sync and ignorestate is not set' do
        res = described_class.new(resource)
        res[:ensure] = :resumed
        res[:ignorestate] = :true
        ensure_status = double(:resume)
        expect(res.provider).to receive(:resume) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
        expect(res.parameter(:ignorestate).value).to be true
      end
    end

end
