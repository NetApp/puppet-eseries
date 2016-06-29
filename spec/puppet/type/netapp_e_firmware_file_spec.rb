require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_firmware_file) do
  before :each do
    @firmware_file = {  :name => 'name',
                    :filename => 'N5468-820834-DB2.dlp',
                    :folderlocation => 'C://upgrade',
                    :validate_file => true }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @firmware_file
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :filename, :folderlocation, :validate_file, :version].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        resource[:id] = 'id'
        described_class.attrtype(prop).should == :property
      end
    end

    [:filename].each do |param|
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
    context 'for filename' do
      it_behaves_like 'a string param/property', :filename, true
    end
    context 'for folderlocation' do
      it_behaves_like 'a string param/property', :folderlocation, true
    end
    context 'for validate_file' do
      it_behaves_like 'a boolean param', :validate_file, true
    end
    context 'for version' do
      it_behaves_like 'a string param/property', :version, true
    end
  end

end