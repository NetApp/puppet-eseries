require 'spec/spec_helper'
require 'rspec/expectations'

def raise_status_error(message, response, &block)
  message = "#{message}. Response: #{response[:status]}  #{response[:body]}"
  raise_error(RuntimeError, message, &block)
end

shared_examples 'a simple API call' do |method, expected_status|
  before(:each) do
    @expect_in_request.merge!(:method => method,
                              :url => @url + uri
    )
  end
  it "should succeed when response status code is #{expected_status}" do
    @response[:status] = expected_status
    Excon.stub(@expect_in_request, @response)
    expect(method_call).to eq(@expected_result || true)
  end
  it "should raise RuntimeError when response status code is not #{expected_status}" do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { method_call }.to raise_status_error(fail_message, @response)
  end
end

shared_examples 'a call based on storage systems' do |uri_suffix|
  before(:each) do
    @storage_req = @expect_in_request.merge(
        :url => @url + '/devmgr/v2/storage-systems/')
  end
  it 'should return empty array if no storage systems' do
    @response.merge!(:body => JSON.generate([]))
    Excon.stub @storage_req, @response
    expect(method_call).to eq([])
  end

  it 'should return array from response if storage systems exists' do
    Excon.stub @storage_req, @response
    result = []
    @body.each do |i|
      item = { 'storage_id' => i['id'],
               'key1' => 'value1',
               'key2' => 'value2' }
      result << item.merge('storagesystem' => i['id'])

      url = @url + "/devmgr/v2/storage-systems/#{i['id']}/#{uri_suffix}"
      storage_conf_req = @expect_in_request.merge(:url => url)
      res = @response.merge(:body => JSON.generate([item]))
      Excon.stub(storage_conf_req, res)
    end
    expect(method_call).to eq(result)
  end

  it 'should raise RuntimeError if status code is not 200' do
    sys_id = 'sys_id'
    @response.merge!(:body => JSON.generate([{ 'id' => sys_id }]))
    Excon.stub(@storage_req, @response)

    url = @url + "/devmgr/v2/storage-systems/#{sys_id}/#{uri_suffix}"
    res = @response.merge(:status => 404)
    Excon.stub @expect_in_request.merge(:url => url), res
    expect { method_call }.to raise_status_error(fail_message, res)
  end
end

describe NetApp::ESeries::Api do
  before(:each) do
    @user = 'user'
    @password = 'password'
    @verify_ssl = true
    @url = 'http://example.com'
    @connect_timeout = 10
    @netapp_api = NetApp::ESeries::Api.new(@user, @password, @url, @verify_ssl, @connect_timeout)

    @cookies = 'JSESSIONID=vsek549xg1021l2rz513qvrr;Path=/devmgr'
    @expected_cookie = @cookies.split(';').first
    @body = [{ 'id' => 'id_1',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3' },
             { 'id' => 'id_2',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3'
             }]
    @request_body = double('request_body')
    allow(@request_body).to receive(:to_json).and_return(JSON.generate(@body))

    @response = { :body => JSON.generate(@body),
                  :headers => { 'Set-Cookie' => @cookies },
                  :status => 200 }

    @expect_in_request = { :method => :get,
                           :headers => { 'Accept' => 'application/json',
                                         'Content-Type' => 'application/json',
                                         'cookie' => @expected_cookie } }

    Excon.stub({}, @response)
    @netapp_api.login
    Excon.stubs.clear
  end

  after(:each) do
    Excon.stubs.clear
  end

  context 'initialize:' do
    it 'should initialize without connection_timoeut' do
      api = NetApp::ESeries::Api.new(@user, @url, @password, @basic_auth)
      expect(api).to be_instance_of(NetApp::ESeries::Api)
    end
    it 'url should be readable' do
      expect(@netapp_api.url).to eq(@url)
    end
    it 'url should not be writable' do
      expect { @netapp_api.url = 'other.com' }.to raise_error(NoMethodError)
    end
  end

  context 'login:' do
    before(:each) do
      # For login tests we reset @netapp_api
      @netapp_api = NetApp::ESeries::Api.new(@user, @password, @url, @basic_auth, @connect_timeout)
      @expect_in_request.merge!(:method => :post,
                                :url => @url + '/devmgr/utils/login')
      @expect_in_request[:headers]['cookie'] = nil
    end

    it 'succeeds when credentials are correct' do
      @response[:status] = 200
      Excon.stub(@expect_in_request, @response)
      @netapp_api.login
    end

    it 'fails when credentials are wrong' do
      @response[:status] = 204
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.login }.to raise_error(RuntimeError, 'Login failed. HTTP error- 204')
    end
  end

  context 'get_storage_systems' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_storage_systems).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_storage_systems }.to raise_status_error('Could not get info about storage systems', @response)
    end
  end

  context 'get_network_interfaces' do
    it_behaves_like 'a call based on storage systems', 'configuration/ethernet-interfaces/' do
      let(:method_call) { @netapp_api.get_network_interfaces }
      let(:fail_message) { 'Could not get network interfaces information' }
    end
  end

  context 'update_ethernet_interface' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/configuration/ethernet-interfaces/' }
      let(:method_call) { @netapp_api.update_ethernet_interface 'sys_id', @request_body }
      let(:fail_message) { 'Could not update network interfaces' }
    end
  end

  context 'create_storage_system' do
    it_behaves_like 'a simple API call', :post, 201 do
      let(:uri) { '/devmgr/v2/storage-systems' }
      let(:method_call) { @netapp_api.create_storage_system @request_body }
      let(:fail_message) { 'Storage Creation Failed' }
    end
  end

  context 'delete_storage_system' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id' }
      let(:method_call) { @netapp_api.delete_storage_system 'sys_id' }
      let(:fail_message) { 'Storage Deletion Failed' }
    end
  end

  context 'update_storage_system' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id' }
      let(:method_call) { @netapp_api.update_storage_system 'sys_id', @request_body }
      let(:fail_message) { 'Could not update storage system' }
    end
  end

  context 'get_passwords_status' do
    before(:each) do
      body_response = { 'key' => 'value' }
      @response[:body] = JSON.generate(body_response)
      @expected_result = body_response.merge(:storagesystem => 'sys_id')
    end
    it_behaves_like 'a simple API call', :get, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/passwords/' }
      let(:method_call) { @netapp_api.get_passwords_status 'sys_id' }
      let(:fail_message) { 'Could not get information about storage passwords' }
    end
  end

  context 'change_password' do
    it_behaves_like 'a simple API call', :post, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/passwords/' }
      let(:method_call) { @netapp_api.change_password 'sys_id', @request_body }
      let(:fail_message) { 'Password Update Failed' }
    end
  end

  context 'get_hosts' do
    before(:each) do
      @storage_req = @expect_in_request.merge(
          :url => @url + '/devmgr/v2/storage-systems/')
    end
    it 'should return empty array if no storage systems' do
      @response.merge!(:body => JSON.generate([]))
      Excon.stub @storage_req, @response
      expect(@netapp_api.get_hosts).to eq([])
    end

    it 'should return hosts arrays merged if storage systems exists' do
      Excon.stub @storage_req, @response
      @expected = []

      def stub_host_request
        @body.each do |i|
          item = { 'storage_id' => i['id'],
                   'hostSidePorts' => ['address' => 'fqdn.domain.com'],
                   'initiators' => ['initiatorRef' => 'abc1234']
          }
          expected_item = { 'storage_id' => i['id'],
                            'hostSidePorts' => ['port' => 'fqdn.domain.com'],
                            'initiators' => ['initiatorRef' => 'abc1234'],
                            'storagesystem' => i['id'],
                            'initiators_ref_numbers' => ['abc1234']
          }
          @expected << expected_item

          url = @url + "/devmgr/v2/storage-systems/#{i['id']}/hosts"
          storage_conf_req = @expect_in_request.merge(:url => url)
          res = @response.merge(:body => JSON.generate([item]))
          Excon.stub(storage_conf_req, res)
        end
      end

      stub_host_request
      cmp = lambda { |x, y| y['storage_id'] <=> x['storage_id'] }
      expect(@netapp_api.get_hosts.sort(&cmp)).to eq(@expected.sort(&cmp))
    end

    it 'should raise RuntimeError if hosts request return status code is not 200' do
      sys_id = 'sys_id'
      @response.merge!(:body => JSON.generate([{ 'id' => sys_id }]))
      Excon.stub(@storage_req, @response)
      url = @url + "/devmgr/v2/storage-systems/#{sys_id}/hosts"
      res = @response.merge(:status => 404)
      Excon.stub @expect_in_request.merge(:url => url), res
      expect { @netapp_api.get_hosts }.to raise_status_error('Could not get hosts information', res)
    end
  end

  context 'create_host' do
    it_behaves_like 'a simple API call', :post, 201 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/hosts' }
      let(:method_call) { @netapp_api.create_host 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create host' }
    end
  end

  context 'update_host' do
    it_behaves_like 'a simple API call', :post, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/hosts/host_id' }
      let(:method_call) { @netapp_api.update_host 'sys_id', 'host_id', @request_body }
      let(:fail_message) { 'Failed update host host_id' }
    end
  end

  context 'delete_host' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/hosts/host_id' }
      let(:method_call) { @netapp_api.delete_host 'sys_id', 'host_id' }
      let(:fail_message) { 'Failed to delete host' }
    end
  end

  context 'get_host_groups' do
    it_behaves_like 'a call based on storage systems', 'host-groups' do
      let(:method_call) { @netapp_api.get_host_groups }
      let(:fail_message) { 'Could not get host groups information' }
    end
  end

  context 'create_host_group' do
    it_behaves_like 'a simple API call', :post, 201 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/host-groups' }
      let(:method_call) { @netapp_api.create_host_group 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create host group' }
    end
  end

  context 'delete_host_group' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/host-groups/hg_id' }
      let(:method_call) { @netapp_api.delete_host_group 'sys_id', 'hg_id' }
      let(:fail_message) { 'Failed to delete host group' }
    end
  end

  context 'get_storage_pools' do
    it_behaves_like 'a call based on storage systems', 'storage-pools/' do
      let(:method_call) { @netapp_api.get_storage_pools }
      let(:fail_message) { 'Failed to get storage pool information' }
    end
  end

  context 'create_storage_pool' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/storage-pools' }
      let(:method_call) { @netapp_api.create_storage_pool 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create storage pool' }
    end
  end

  context 'delete_storage_pool' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/storage-pools/pool_id' }
      let(:method_call) { @netapp_api.delete_storage_pool 'sys_id', 'pool_id' }
      let(:fail_message) { 'Failed to delete storage pool' }
    end
  end

  context 'get_snapshot_groups' do
    it_behaves_like 'a call based on storage systems', 'snapshot-groups/' do
      let(:method_call) { @netapp_api.get_snapshot_groups }
      let(:fail_message) { 'Failed to get snapshot group information' }
    end
  end

  context 'create_snapshot_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/snapshot-groups' }
      let(:method_call) { @netapp_api.create_snapshot_group 'sys_id', @request_body }
      let(:fail_message) { 'Failed to creat snapshot group' }
    end
  end

  context 'delete_snapshot_group' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/snapshot-groups/sg_id' }
      let(:method_call) { @netapp_api.delete_snapshot_group 'sys_id', 'sg_id' }
      let(:fail_message) { 'Failed to delete snapshot group' }
    end
  end

  context 'update_snapshot_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/snapshot-groups/sg_id' }
      let(:method_call) { @netapp_api.update_snapshot_group 'sys_id', 'sg_id', @request_body }
      let(:fail_message) { 'Failed to update snapshot group' }
    end
  end

  context 'get_volumes' do
    before(:each) do
      @storage_req = @expect_in_request.merge(
          :url => @url + '/devmgr/v2/storage-systems/')
    end
    it 'should return empty array if no storage systems' do
      @response.merge!(:body => JSON.generate([]))
      Excon.stub @storage_req, @response
      expect(@netapp_api.get_volumes).to eq([])
    end

    it 'should return volume arrays merged if storage systems exists' do
      Excon.stub @storage_req, @response
      @expected = []

      def stub_volume_requests(type)
        @body.each do |i|
          item = { 'storage_id' => i['id'],
                   'key1' => 'value1',
                   'key2' => 'value2',
                   'type' => type
          }
          @expected << item.merge('storagesystem' => i['id'])

          url = @url + "/devmgr/v2/storage-systems/#{i['id']}/#{type}"
          storage_conf_req = @expect_in_request.merge(:url => url)
          res = @response.merge(:body => JSON.generate([item]))
          Excon.stub(storage_conf_req, res)
        end
      end

      stub_volume_requests('volumes')
      stub_volume_requests('thin-volumes')
      cmp = lambda { |x, y| y['storage_id'] <=> x['storage_id'] }
      expect(@netapp_api.get_volumes.sort(&cmp)).to eq(@expected.sort(&cmp))
    end

    it 'should raise RuntimeError if volumes request return status code is not 200' do
      sys_id = 'sys_id'
      @response.merge!(:body => JSON.generate([{ 'id' => sys_id }]))
      Excon.stub(@storage_req, @response)
      url = @url + "/devmgr/v2/storage-systems/#{sys_id}/volumes"
      res = @response.merge(:status => 404)
      Excon.stub @expect_in_request.merge(:url => url), res
      expect { @netapp_api.get_volumes }.to raise_status_error('Failed to get volumes information', res)
    end

    it 'should raise RuntimeError if thin-volumes request return status code is not 200' do
      sys_id = 'sys_id'
      @response.merge!(:body => JSON.generate([{ 'id' => sys_id }]))
      Excon.stub(@storage_req, @response)
      url = @url + "/devmgr/v2/storage-systems/#{sys_id}/volumes"
      Excon.stub @expect_in_request.merge(:url => url), @response

      url = @url + "/devmgr/v2/storage-systems/#{sys_id}/thin-volumes"
      res = @response.merge(:status => 404)
      Excon.stub @expect_in_request.merge(:url => url), res
      expect { @netapp_api.get_volumes }.to raise_status_error('Failed to get thin-volumes information', res)
    end
  end

  context 'create_volume' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/volumes' }
      let(:method_call) { @netapp_api.create_volume 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create volume' }
    end
  end

  context 'delete_volume' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/volumes/vol_id' }
      let(:method_call) { @netapp_api.delete_volume 'sys_id', 'vol_id' }
      let(:fail_message) { 'Failed to delete volume' }
    end
  end

  context 'create_thin_volume' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/thin-volumes' }
      let(:method_call) { @netapp_api.create_thin_volume 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create thin volume' }
    end
  end

  context 'delete_thin_volume' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/thin-volumes/volume_id' }
      let(:method_call) { @netapp_api.delete_thin_volume 'sys_id', 'volume_id' }
      let(:fail_message) { 'Failed to delete thin volume' }
    end
  end

  context 'storage_pool_id' do
    before(:each) do
      @sys_id = 'sys_id'
      @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/storage-pools"
    end
    it 'should return nil if pool label does not match given name' do
      name = 'name'
      @response[:body] = JSON.generate([{ 'id' => 'pool_id',
                                          'label' => 'not_name',
                                          'key' => 'value' },
                                        { 'id' => 'pool_id2',
                                          'label' => 'not_name2',
                                          'key' => 'value' }
                                       ])
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.storage_pool_id @sys_id, name).to be_nil
    end

    it 'should return nil if storage system do not have pools' do
      name = 'name'
      @response[:body] = JSON.generate([])
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.storage_pool_id @sys_id, name).to eq(nil)
    end
    it 'should return pool id if pool label matches given name' do
      name = 'name'
      @response[:body] = JSON.generate([{ 'id' => 'pool_id',
                                          'label' => 'not_name',
                                          'key' => 'value' },
                                        { 'id' => 'pool_id2',
                                          'label' => name,
                                          'key' => 'value' }
                                       ])
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.storage_pool_id @sys_id, name).to eq('pool_id2')
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.storage_pool_id @sys_id, 'name' }.to raise_status_error('Failed to get pool id', @response)
    end
  end

  context 'create_mirror_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/async-mirrors' }
      let(:method_call) { @netapp_api.create_mirror_group 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create mirror group' }
    end
  end

  context 'delete_mirror_group' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/async-mirrors/mirror_id' }
      let(:method_call) { @netapp_api.delete_mirror_group 'sys_id', 'mirror_id' }
      let(:fail_message) { 'Failed to delete mirror group' }
    end
  end

  context 'update_mirror_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/async-mirrors/mirror_id' }
      let(:method_call) { @netapp_api.update_mirror_group 'sys_id', 'mirror_id', @request_body }
      let(:fail_message) { 'Failed to update mirror group' }
    end
  end

  context 'get_mirror_groups' do
    it_behaves_like 'a call based on storage systems', 'async-mirrors' do
      let(:method_call) { @netapp_api.get_mirror_groups }
      let(:fail_message) { 'Failed to get mirror groups' }
    end
  end
end
