require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_map) do
  before :each do
    @netapp_e_map = { :name => 'netapp_e_map',
                      :storagesystem => 'storagesystem',
                      :source => 'source',
                      :target => 'target',
                      :type => :host,
                      :lun => 'lun',
                      :ensure => :present }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @netapp_e_map
  end

  let :providerclass do
    described_class.provide(:fake_storage_system_provider) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :storagesystem, :source, :target, :type, :lun].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end

    [:id, :ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end

    [:name, :storagesystem, :source, :target, :lun].each do |param|
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
    context 'for source' do
      it_behaves_like 'a string param/property', :source, true
    end
    context 'for target' do
      it_behaves_like 'a string param/property', :target, true
    end
    context 'for type' do
      it_behaves_like 'a enum param/property', :type, [:host, :hostgroup]
    end
    context 'for lun' do
      it_behaves_like 'a string param/property', :lun, true
    end
    context 'for ensure' do
      it_behaves_like 'a enum param/property', :ensure, [:present, :absent]
      it 'should provider.create when :present and syncing' do
        res = described_class.new(resource)
        expect(res.provider).to receive(:create).with(resource[:storagesystem],
                                                      resource[:source],
                                                      resource[:target],
                                                      resource[:type],
                                                      resource[:lun]) { 'created' }
        expect(res.property(:ensure).sync).to eq('created')
      end
      it 'should provider.destroy when :absent and syncing' do
        res = described_class.new(resource)
        res[:ensure] = :absent
        expect(res.provider).to receive(:destroy).with(resource[:storagesystem],
                                                       resource[:lun]) { 'destroyed' }
        expect(res.property(:ensure).sync).to eq('destroyed')
      end
      describe 'when retrieve' do
        it 'should raise Puppet::Error if transport returned error' do
          res = described_class.new(resource)
          transport = double 'transport'
          expect(transport).to receive(:get_lun_mapping).and_raise(RuntimeError)
          expect(res.provider).to receive(:transport) { transport }
          expect { res.parameter(:ensure).retrieve }.to raise_error(Puppet::Error)
        end
        it 'should return lun_mapping' do
          res = described_class.new(resource)
          transport = double 'transport'
          lun_mapping = double 'lun_mapping'
          expect(transport).to receive(:get_lun_mapping).with(resource[:storagesystem],
                                                              resource[:lun]) { lun_mapping }
          expect(res.provider).to receive(:transport) { transport }
          expect(res.parameter(:ensure).retrieve).to be(lun_mapping)
        end
      end
    end
  end
end
