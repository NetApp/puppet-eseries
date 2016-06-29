require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_consistency_group) do
  before :each do
    @consistency_group = {  :name => 'Create_CG1',
                            :consistencygroup => 'CGname',
                            :storagesystem => 'ssid116117',
                            :repositoryfullpolicy => 'purgepit',
                            :ensure => :present }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @consistency_group
  end

  let :providerclass do
    described_class.provide(:consistency_group_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name,:consistencygroup].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure, :storagesystem, :id,:fullwarnthresholdpercent,:autodeletethreshold,:repositoryfullpolicy,:rollbackpriority].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:storagesystem, :consistencygroup].each do |param|
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
      it_behaves_like 'a string param/property', :consistencygroup, false
    end
    context 'for fullwarnthresholdpercent' do
      it_behaves_like 'a integer param/property', :fullwarnthresholdpercent, 0, 100
    end
    context 'for autodeletethreshold' do
      it_behaves_like 'a integer param/property', :autodeletethreshold, 0, 32
    end
    context 'for repositoryfullpolicy' do
      it_behaves_like 'a enum param/property', :repositoryfullpolicy, ['purgepit', 'failbasewrites']
    end
    context 'for rollbackpriority' do
      it_behaves_like 'a enum param/property', :rollbackpriority, ['highest', 'high', 'medium', 'low', 'lowest']
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
          expect(res.provider).to receive(:exist?) { ensure_status }
          expect(res.parameter(:ensure).retrieve).to be ensure_status
        end
        it ' if resource is absent it should return absent' do
          ensure_status = double(:absent)
          res = described_class.new(resource)
          expect(res.provider).to receive(:exist?) { ensure_status }
          expect(res.parameter(:ensure).retrieve).to be ensure_status
        end
      end
    end
  end
end
