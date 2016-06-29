require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_firmware_file).provider(:netapp_e_firmware_file) do
  before :each do
    Puppet::Type.type(:netapp_e_firmware_file).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_firmware_file).new(
        :name => 'name',
        :filename => 'RC_08200300_e10_820_5468.dlp',
        :folderlocation => '/root',
        :validate_file => true,
        :ensure => :present
    )
  end

  let :provider do
    described_class.new(
        :name => 'name'
    )
  end

  describe 'when asking exists?' do
    it 'should return :present if resource is present' do

      expect(@transport).to receive(:get_firmware_files) { [ { 'filename' => 'RC_08200400_e10_820_5468.dlp', 'version' => '08.20.04.00' },
                                                              { 'filename' => 'RC_08200300_e10_820_5468.dlp', 'version' => '08.20.03.00' } ]
                                                         }
      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exists?).to eq(:present)
    end
    
    it 'should return :absent if resource is absent' do

      expect(@transport).to receive(:get_firmware_files) { [] }
      allow(resource.provider).to receive(:transport) { @transport }
      expect(resource.provider.exists?).to eq(:absent)
    end
  end

  describe 'when creating a resource' do

    it 'should raise error when filepath is invalid' do
      filepath = 'invalidfilepath'
      expect {resource.provider.upload}.to raise_error(Puppet::Error)
    end

    it 'should be able to create it' do
      filepath = "#{resource[:folderlocation]}/#{resource[:filename]}"
      expect(@transport).to receive(:upload_firmware_file).with(filepath,resource[:validate_file]) { { 'fileName' => 'RC_08200300_e10_820_5468.dlp', 'version' => '08.20.03.00' } }
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.upload
    end

    it 'should raise error when file was not uploaded successfully' do
      filepath = "#{resource[:folderlocation]}/#{resource[:filename]}"
      expect(@transport).to receive(:upload_firmware_file).with(filepath,resource[:validate_file]) { }
      allow(resource.provider).to receive(:transport) { @transport }
      expect {resource.provider.upload}.to raise_error(Puppet::Error)
    end

  end

  describe 'when destroying a resource' do

    it 'should raise error when file does not exists on server' do
      resource[:version] = ''
      expect {resource.provider.upload}.to raise_error(Puppet::Error)
    end

    it 'should be able to delete it' do
      resource[:version] = '08.20.03.00'
      expect(@transport).to receive(:delete_firmware_file).with(resource[:filename])
      allow(resource.provider).to receive(:transport) { @transport }
      resource.provider.delete
    end

  end

end
