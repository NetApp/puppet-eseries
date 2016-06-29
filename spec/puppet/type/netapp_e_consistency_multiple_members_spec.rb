require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_consistency_multiple_members) do
  before :each do
    @consistency_group_members = {  :name => 'ResourceName',
                            :volumes => [{
                                          'repositorypool'    => 'Disk_Pool_1',
                                          'volume'            => 'Volume-1',
                                          'scanmedia'         => true,
                                          'validateparity'    => true,
                                          'repositorypercent' => 10,
                                        },
                                        {
                                          'repositorypool'    => 'Disk_Pool_1',
                                          'volume'            => 'Volume-2',
                                          'scanmedia'         => false,
                                          'validateparity'    => false,
                                        }],
                            :storagesystem => 'ssid116117',
                            :consistencygroup => 'CGname'}
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @consistency_group_members
  end

  let :providerclass do
    described_class.provide(:netapp_e_consistency_multiple_members) { mk_resource_methods }
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

    [:storagesystem, :volumes].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:volumes,:consistencygroup, :storagesystem].each do |param|
      it "#{param} should be a required" do
        resource.delete(param)
        expect { described_class.new(resource) }.to raise_error Puppet::Error
      end
    end
  end

  describe 'when validating values' do
    context 'for volumes' do
      it_behaves_like 'a array_matching param', :volumes, {
                                          'repositorypool'    => 'Disk_Pool_1',
                                          'volume'            => 'Volume-1',
                                          'scanmedia'         => true,
                                          'validateparity'    => true,
                                          'repositorypercent' => 10,
                                        }, 
                                       [{
                                          'repositorypool'    => 'Disk_Pool_1',
                                          'volume'            => 'Volume-1',
                                          'scanmedia'         => true,
                                          'validateparity'    => true,
                                          'repositorypercent' => 10,
                                        },
                                        {
                                          'repositorypool'    => 'Disk_Pool_1',
                                          'volume'            => 'Volume-2',
                                          'scanmedia'         => true,
                                          'validateparity'    => true,
                                          'repositorypercent' => 10,
                                        }]
    end
    context 'for consistencygroup' do
      it_behaves_like 'a string param/property', :consistencygroup, true
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
      describe 'when retrieve' do
        it ' it should add volumes which are not already added' do
          message = 'some message'
          res = described_class.new(resource)
          expect(res.provider).to receive(:addvolumes) {message}
          expect(res.parameter(:storagesystem).retrieve).to be message
        end
      end
    end
  end
end