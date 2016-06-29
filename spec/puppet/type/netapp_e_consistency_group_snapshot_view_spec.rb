require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_consistency_group_snapshot_view) do
  before :each do
    @netapp_e_password = { :name => 'cc',
                           :storagesystem => 'ssid116117',
                           :consistencygroup => 'Create_CG1',
                           :viewname => 'vname',
                           :ensure => :present,
                           :snapshotnumber => 1
                         }
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
    [:name, :storagesystem, :consistencygroup, :viewname, :snapshotnumber, :viewtype, :validateparity, :repositorypool, :accessmode, :repositorypercent, :volume, :scanmedia, :pitid, :repositorypoolid].each do |param|
      it "should have a #{param} parameter" do
        described_class.attrtype(param).should == :param
      end
    end
    [:ensure].each do |prop|
      it "should have a #{prop} property" do
        described_class.attrtype(prop).should == :property
      end
    end
    [:name, :storagesystem, :consistencygroup, :viewname].each do |param|
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
    context 'for viewname' do
      it_behaves_like 'a string param/property', :viewname
    end
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for consistencygroup' do
      it_behaves_like 'a string param/property', :consistencygroup
    end
    context 'for snapshotnumber' do
      it_behaves_like 'a string param/property', :snapshotnumber, true
    end
    context 'for viewtype' do
      it_behaves_like 'a enum param/property', :viewtype, ['byVolume', 'bySnapshot'], 'bySnapshot'
    end
    context 'for validateparity' do
      it_behaves_like 'a boolean param', :validateparity
    end
    context 'for repositorypool' do
      it_behaves_like 'a string param/property', :repositorypool, true
    end
    context 'for accessmode' do
      it_behaves_like 'a enum param/property', :accessmode, ['readWrite', 'readOnly'], 'readWrite'
    end
    context 'for repositorypercent' do
      it_behaves_like 'a integer param/property', :repositorypercent, 0, 100
    end
    context 'for scanmedia' do
      it_behaves_like 'a boolean param', :scanmedia
    end
    context 'for volume' do
      it_behaves_like 'a string param/property', :volume, true
    end
    context 'for pitid' do
      it_behaves_like 'a string param/property', :pitid, true
    end
    context 'for repositorypoolid' do
      it_behaves_like 'a string param/property', :repositorypoolid, true
    end

    context 'for ensure' do
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
      it 'should set ensure to present when sync and validateparity is set to true' do
        res = described_class.new(resource)
        res[:ensure] = :present
        res[:viewtype] = 'bySnapshot'
        res[:snapshotnumber] = '1'
        res[:validateparity] = true
        ensure_status = double(:present)

        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to present when sync and validateparity is set to false' do
        res = described_class.new(resource)
        res[:ensure] = :present
        res[:viewtype] = 'bySnapshot'
        res[:snapshotnumber] = '1'
        res[:validateparity] = false
        ensure_status = double(:present)
        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
      it 'should set ensure to present when sync and validateparity is not set' do
        res = described_class.new(resource)
        res[:ensure] = :present
        res[:viewtype] = 'bySnapshot'
        res[:snapshotnumber] = '1'
        ensure_status = double(:present)
        expect(res.provider).to receive(:create) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
        expect(res.parameter(:validateparity).value).to be false
      end
      it 'should raise error when ensure is present but viewtype is not set' do
        res = described_class.new(resource)
        res[:ensure] = :present
        res[:snapshotnumber] = '1'
        res[:validateparity] = false
        ensure_status = double(:present)
        expect { described_class.new(res) }.to raise_error NoMethodError
      end
      it 'should raise error when ensure is present but snapshotnumber is not set' do
        res = described_class.new(resource)
        res[:ensure] = :present
        res[:viewtype] = 'bySnapshot'
        res[:validateparity] = false
        ensure_status = double(:present)
        expect { described_class.new(res) }.to raise_error NoMethodError
      end
      it 'should set ensure to absent when sync' do
        res = described_class.new(resource)
        ensure_status = double(:absent)
        res[:ensure] = :absent
        expect(res.provider).to receive(:destroy) { ensure_status }
        expect(res.property(:ensure).sync).to be ensure_status
      end
    end

  end

end
