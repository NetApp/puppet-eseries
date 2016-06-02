require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_firmware_upgrade).provider(:netapp_e_firmware_upgrade) do
  before :each do
    Puppet::Type.type(:netapp_e_firmware_upgrade).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_firmware_upgrade).new(
        :name => 'name',
        :storagesystem => 'ssid1819',
        :firmwaretype => 'nvsramfile',
        :filename => 'N5468-820834-DB2.dlp',
        :melcheck => false,
        :compatibilitycheck => true,
        :releasedbuildonly => true,
        :waitforcompletion => true,
        :ensure => :upgraded
    )
  end

  let :provider do
    described_class.new(
        :name => 'upgrade_firmware'
    )
  end

  context 'when upgrading a resource with nvsramfile file' do
    before :each do
        resource.provider.set(:firmwaretype => 'nvsramfile')
        resource.provider.set(:filename => 'N5468-820834-DB2.dlp')
        resource.provider.set(:ensure => :upgraded)      
    end

    it 'should upgrade when compatibility check done successfully.' do
      resource[:firmwaretype] = 'nvsramfile'
      resource[:filename] = 'N5468-820834-DB2.dlp'
      resource[:ensure] = 'upgraded'
      firmware_response = Excon::Response.new
      firmware_response.body = File.read(my_fixture('firmware_upgrade_list.json'))
      firmware_response.status = 200
      upgrade_req_json = { 'requestId' => '1' }
      upgrade_request_body = {:stageFirmware => false,:skipMelCheck => true,:nvsramFile => 'N5468-820834-DB2.dlp'}
      expect(@transport).to receive(:get_firmware_upgrade_details).with(resource[:storagesystem]) {firmware_response}
      expect(@transport).to receive(:check_firmware_compatibility) { upgrade_req_json }
      expect(@transport).to receive(:get_firmware_compatibility_check_status).with(upgrade_req_json['requestId']) {JSON.parse(File.read(my_fixture('check_compatibility_list.json'))) }
      expect(@transport).to receive(:upgrade_controller_firmware).with(resource[:storagesystem],upgrade_request_body) { upgrade_req_json }
      expect(@transport).to receive(:get_firmware_upgrade_details).with(resource[:storagesystem]) {firmware_response}
      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.upgrade false
    end
  end

  context 'when upgrading/staging a resource with cfwfile file' do
    before :each do
        resource.provider.set(:firmwaretype => 'cfwfile')
        resource.provider.set(:filename => 'CFWFILE.dlp')
        resource.provider.set(:ensure => :staged)
    end

    it 'should upgrade/stage when found on server and file compatibility check done successfully.' do
      resource[:firmwaretype] = 'cfwfile'
      resource[:filename] = 'CFWFILE.dlp'
      resource[:ensure] = 'staged'
      firmware_response = Excon::Response.new
      firmware_response.body = File.read(my_fixture('firmware_upgrade_list.json'))
      firmware_response.status = 200
      upgrade_req_json = { 'requestId' => '1' }
      upgrade_request_body = {:stageFirmware => true,:skipMelCheck => true,:cfwFile => 'CFWFILE.dlp'}
      expect(@transport).to receive(:get_firmware_files) {JSON.parse(File.read(my_fixture('firmware_file_list.json'))) }
      expect(@transport).to receive(:get_firmware_upgrade_details).with(resource[:storagesystem]) {firmware_response}
      expect(@transport).to receive(:check_firmware_compatibility) { upgrade_req_json }
      expect(@transport).to receive(:get_firmware_compatibility_check_status).with(upgrade_req_json['requestId']) {JSON.parse(File.read(my_fixture('check_compatibility_list.json'))) }
      expect(@transport).to receive(:upgrade_controller_firmware).with(resource[:storagesystem],upgrade_request_body) { upgrade_req_json }
      expect(@transport).to receive(:get_firmware_upgrade_details).with(resource[:storagesystem]) {firmware_response}
      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.upgrade true
    end

  end

  context 'when activating a resource with cfwfile file' do
    before :each do
        resource.provider.set(:firmwaretype => 'cfwfile')
        resource.provider.set(:filename => 'CFWFILE.dlp')
        resource.provider.set(:waitforcompletion => false)
        resource.provider.set(:ensure => :activated)
    end

    it 'should avtivate firmware' do
      resource[:firmwaretype] = 'cfwfile'
      resource[:filename] = 'CFWFILE.dlp'
      resource[:waitforcompletion] = false
      resource[:ensure] = 'activated'
      firmware_response = Excon::Response.new
      firmware_response.body = File.read(my_fixture('firmware_upgrade_list.json'))
      firmware_response.status = 200
      expect(@transport).to receive(:get_firmware_upgrade_details).with(resource[:storagesystem]) {firmware_response}
      expect(@transport).to receive(:activate_controller_firmware).with(resource[:storagesystem],{:skipMelCheck => true}) { {'requestId' => '1'} }
      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.activate
    end

  end

end
