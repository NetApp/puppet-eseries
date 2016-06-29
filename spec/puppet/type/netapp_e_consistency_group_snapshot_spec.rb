require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_consistency_group_snapshot) do
  before :each do
    @netapp_e_password = { :name => 'cc',
                           :storagesystem => 'ssid116117',
                           :consistencygroup => 'Create_CG1',
                           :ensure => :present}
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_password
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :storagesystem, :consistencygroup, :cg_id].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:name, :storagesystem, :consistencygroup].each do |param|
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
    context 'for consistencygroup' do
      it_behaves_like 'a string param/property', :consistencygroup
    end
    context 'for ensure' do
      it 'should set ensure to present when sync' do
        res = described_class.new(resource)
        ensure_status = double(:present)
        res[:ensure] = :present
        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to absent when sync' do
        res = described_class.new(resource)
        ensure_status = double(:absent)
        res[:ensure] = :absent
        expect(res.provider).to receive(:destroy) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it_behaves_like 'a enum param/property', :ensure, %w(present absent), :present
      describe 'when retrieve' do
        it ' if resource is present it should return present' do
          ensure_status = double(:present)
          res = described_class.new(resource)
          expect(res.provider).to receive(:exists?) { ensure_status }
          expect(res.parameter(:ensure).retrieve).to be ensure_status
        end
        it ' if resource is absent it should return absent' do
          ensure_status = double(:absent)
          res = described_class.new(resource)
          expect(res.provider).to receive(:exists?) { ensure_status }
          expect(res.parameter(:ensure).retrieve).to be ensure_status
        end
      end
    end
  end

end
