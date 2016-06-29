require 'spec/spec_helper'
require 'spec/support/shared_examples_for_types'

describe Puppet::Type.type(:netapp_e_firmware_upgrade) do
  before :each do
    @firmware_file = {  :name => 'name',
                        :storagesystem => 'ssid1819',
                        :firmwaretype => 'nvsramfile',
                        :filename => 'N5468-820834-DB2.dlp',
                        :melcheck => false,
                        :compatibilitycheck => true,
                        :releasedbuildonly => true,
                        :waitforcompletion => true }
    described_class.stubs(:defaultprovider).returns providerclass
  end

  let :resource do
    @firmware_file
  end

  let :providerclass do
    described_class.provide(:netapp_e_firmware_upgrade) { mk_resource_methods }
  end

  it 'should have :name be its namevar' do
    described_class.key_attributes.should == [:name]
  end

  describe 'when validating attributes' do
    [:name, :filename, :firmwaretype, :storagesystem, :melcheck, :compatibilitycheck,
     :releasedbuildonly, :waitforcompletion, :requestid, :comp_check_requestid, :uploadendtime,
     :activateendtime, :version].each do |param|
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

    [:storagesystem,:firmwaretype].each do |param|
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
    context 'for storagesystem' do
      it_behaves_like 'a string param/property', :storagesystem, true
    end
    context 'for firmwaretype' do
      context 'should acccept' do
        ['nvsramfile', 'cfwfile'].each do |val|
          it "#{val}" do
            resource[:firmwaretype] = val
            expected = val
            if val.instance_of?(String)
              expected = val.to_sym
            elsif ( !!val == val) # if boolean type
              expected = val.to_s.to_sym
            end
            described_class.new(resource)[:firmwaretype].should == expected
          end
        end
      end
    end
    context 'for melcheck' do
      it_behaves_like 'a boolean param', :melcheck, false
    end
    context 'for compatibilitycheck' do
      it_behaves_like 'a boolean param', :compatibilitycheck, true
    end
    context 'for releasedbuildonly' do
      it_behaves_like 'a boolean param', :releasedbuildonly, true
    end
    context 'for waitforcompletion' do
      it_behaves_like 'a boolean param', :waitforcompletion, true
    end
    context 'for ensure' do
      context 'should acccept firmwaretype as cfwfile/nvsramfile when ensure is upgraded' do
        ['nvsramfile', 'cfwfile'].each do |val|
          it "#{val}" do
            res = described_class.new(resource)
            ensure_status = double(:upgraded)
            res[:ensure] = :upgraded
            res[:firmwaretype] = val
            expect(res.provider).to receive(:upgrade).with(false) { ensure_status }
            expect(res.property(:ensure).sync).to be ensure_status
          end
        end
      end
      context 'should acccept firmwaretype as only cfwfile when ensure is staged' do
          it 'cfwfile' do
            res = described_class.new(resource)
            ensure_status = double(:staged)
            res[:ensure] = :staged
            res[:firmwaretype] = 'cfwfile'
            expect(res.provider).to receive(:upgrade).with(true) { ensure_status }
            expect(res.property(:ensure).sync).to be ensure_status
          end
      end
      context 'should acccept firmwaretype as only cfwfile when ensure is activated' do
          it 'cfwfile' do
            res = described_class.new(resource)
            ensure_status = double(:activated)
            res[:ensure] = :activated
            res[:firmwaretype] = 'cfwfile'
            expect(res.provider).to receive(:activate) { ensure_status }
            expect(res.property(:ensure).sync).to be ensure_status
          end
      end
    end
  end

end