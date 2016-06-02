require 'spec/spec_helper'
require 'spec/support/shared_examples_for_providers'

describe Puppet::Type.type(:netapp_e_web_proxy_upgrade).provider(:netapp_e_web_proxy_upgrade) do
  before :each do
    Puppet::Type.type(:netapp_e_web_proxy_upgrade).stubs(:defaultprovider).returns described_class
    @transport = double
  end

  let :resource do
    Puppet::Type.type(:netapp_e_web_proxy_upgrade).new(
        :name => 'upgrade_web_proxy',
        :force => 'true',
        :ensure => :upgraded
    )
  end

  let :provider do
    described_class.new(
        :name => 'upgrade_web_proxy'
    )
  end

  context 'when upgrading a resource' do
    it 'should be able to upgrade it' do
      resource[:ensure] = 'upgraded'      
      expect(@transport).to receive(:download_web_proxy_update).with(resource[:force]) { { 'correlationId' => 'a60e6ff9-560c-4463-aa01-7667d5c1cfc3' } }
        
      event_response = Excon::Response.new
      event_response.body =  File.read(my_fixture('event_list.json'))
      event_response.status = 200
      expect(@transport).to receive(:get_events) {event_response}
      
      proxy_upgrade_list = {'stagedVersions'=> [{'context'=> 'devmgr','version' => '01.53.9000.0004'}],'currentVersions' => [{'context' => 'devmgr','version' => '01.53.9000.0003'}]}
      expect(@transport).to receive(:get_web_proxy_update) { proxy_upgrade_list }

      #Activation part
      expect(@transport).to receive(:get_web_proxy_update) { proxy_upgrade_list }
      expect(@transport).to receive(:reload_web_proxy_update) { { 'correlationId' => '78f38d23-b179-4fe3-b3d2-227239312abc' } }
      expect(@transport).to receive(:get_events) {event_response}

      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.upgrade false
    end
  end

  context 'when staging a resource' do
    it 'should be able to stage it' do
       resource[:ensure] = 'staged'      
      expect(@transport).to receive(:download_web_proxy_update).with(resource[:force]) { { 'correlationId' => 'a60e6ff9-560c-4463-aa01-7667d5c1cfc3' } }
        
      event_response = Excon::Response.new
      event_response.body =  File.read(my_fixture('event_list.json'))
      event_response.status = 200
      expect(@transport).to receive(:get_events) {event_response}
      
      proxy_upgrade_list = {'stagedVersions'=> [{'context'=> 'devmgr','version' => '01.53.9000.0004'}],'currentVersions' => [{'context' => 'devmgr','version' => '01.53.9000.0003'}]}
      expect(@transport).to receive(:get_web_proxy_update) { proxy_upgrade_list }

      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.upgrade true
    end
  end

  context 'when activating a resource' do
    it 'should be able to activate it' do
      proxy_upgrade_list = {'stagedVersions'=> [{'context'=> 'devmgr','version' => '01.53.9000.0004'}],'currentVersions' => [{'context' => 'devmgr','version' => '01.53.9000.0003'}]}
      expect(@transport).to receive(:get_web_proxy_update) { proxy_upgrade_list }
      expect(@transport).to receive(:reload_web_proxy_update) { { 'correlationId' => '78f38d23-b179-4fe3-b3d2-227239312abc' } }
      event_response = Excon::Response.new
      event_response.body =  File.read(my_fixture('event_list.json'))
      event_response.status = 200
      expect(@transport).to receive(:get_events) {event_response}
      allow(resource.provider).to receive(:transport) { @transport } 
      resource.provider.activate
    end
  end

end
