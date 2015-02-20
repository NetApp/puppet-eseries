require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_host_group) do
  before :each do
    @netapp_e_host_group = { :name => 'netapp_e_host_group',
                             :storagesystem => 'storagesystem' }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_host_group
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :storagesystem, :hosts].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end

    [:storagesystem, :name].each do |param|
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
    context 'for hosts' do
      it_behaves_like 'a string param/property', :hosts, true
      it_behaves_like 'a array_matching param', :hosts, 'single', %w(val1 val2)
    end
  end
end
