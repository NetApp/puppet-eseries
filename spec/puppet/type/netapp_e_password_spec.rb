require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_password) do
  before :each do
    @netapp_e_password = { :storagesystem => 'netapp_e_password',
                           :current => 'current',
                           :new => 'new',
                           :admin => :true }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_password
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :storagesystem be its namevar' do
    described_class.key_attributes.should == [:storagesystem]
  end

  describe 'when validating attributes' do
    [:storagesystem, :current, :new, :admin, :force].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:storagesystem, :current, :new, :admin].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for current' do
      it_behaves_like 'a string param/property', :current, true
    end
    context 'for new' do
      it_behaves_like 'a string param/property', :new, true
    end
    context 'for admin' do
      it_behaves_like 'a boolean param', :admin
    end
    context 'for force' do
      it_behaves_like 'a boolean param', :force, false
    end
    context 'for ensure' do
      it 'should set password when sync' do
        res = described_class.new(resource)
        password = double(:password)
        expect(res.provider).to receive(:set_password) { password }
        expect(res.property(:ensure).sync).to be password
      end
      it_behaves_like 'a enum param/property', :ensure, %w(set notset), :set
      describe 'when retrieve' do
        it ' if :force is false should return password_status' do
          password_status = double(:password_status)
          res = described_class.new(resource)
          expect(res.provider).to receive(:passwords_status) { password_status }
          expect(res.parameter(:ensure).retrieve).to be password_status
        end
        it ' if :force is true should return return :notset' do
          resource[:force] = true
          expect(described_class.new(resource).parameter(:ensure).retrieve).to eq :notset
        end
      end
    end
  end
end
