require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_consistency_group_rollback) do
  before :each do
    @netapp_e_password = { :name => 'cggrprollback',
                           :storagesystem => 'ssid116117',
                           :consistencygroup => 'CreateCG1',
                           :snapshotnumber => 123}
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
    [:name, :storagesystem, :consistencygroup].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
    [:snapshotnumber].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:name, :storagesystem, :consistencygroup, :snapshotnumber].each do |param|
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
    context 'for snapshotnumber' do
      it_behaves_like 'a integer param/property', :snapshotnumber
      describe 'when retrieve' do
        it 'it should rollback' do
          message = 'some message'
          res = described_class.new(resource)
          expect(res.provider).to receive(:rollback) {message}
          expect(res.parameter(:snapshotnumber).retrieve).to be message
        end
      end
    end
  end

end
