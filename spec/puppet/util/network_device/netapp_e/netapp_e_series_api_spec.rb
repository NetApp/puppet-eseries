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

shared_examples 'a call for entity id based on storage system' do |uri_suffix, tested_method|
  before(:each) do
    @sys_id = 'sys_id'
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/#{uri_suffix}"
    @method = @netapp_api.method(tested_method)
  end
  it 'should return nil if label does not match given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'label' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'label' => 'not_name2',
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to be_nil
  end

  it 'should return nil if storage system do not have entities' do
    name = 'name'
    @response[:body] = JSON.generate([])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq(nil)
  end

  it 'should return entity id if label matches given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'label' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'label' => name,
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq('entity_id2')
  end

  it 'should raise RuntimeError if status code is not 200' do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { @method.call @sys_id, 'name' }.to raise_status_error(fail_message, @response)
  end
end

shared_examples 'a call for entity id based on storage system and by entity name' do |uri_suffix, tested_method|
  before(:each) do
    @sys_id = 'sys_id'
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/#{uri_suffix}"
    @method = @netapp_api.method(tested_method)
  end
  it 'should return false if name does not match given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => 'not_name2',
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to be false
  end

  it 'should return false if storage system do not have entities' do
    name = 'name'
    @response[:body] = JSON.generate([])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq(false)
  end

  it 'should return entity id if name matches given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => name,
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq('entity_id2')
  end

  it 'should raise RuntimeError if status code is not 200' do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { @method.call @sys_id, 'name' }.to raise_status_error(fail_message, @response)
  end
end

shared_examples 'a call for entity id based on storage system and by entity base volume' do |uri_suffix, tested_method|
  before(:each) do
    @sys_id = 'sys_id'
    @cg_id = 'cg_id'
    @seq_no = 'seq_no'
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/consistency-groups/#{@cg_id}/#{uri_suffix}/#{@seq_no}"
    @method = @netapp_api.method(tested_method)
  end
  it 'should return false if basevol does not match given base volume' do
    basevol = 'basevol'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'baseVol' => 'not_basevol',
                                        'key' => 'value' ,
                                        'pitRef' => 'entity_ref'},
                                      { 'id' => 'entity_id2',
                                        'baseVol' => 'not_basevol',
                                        'key' => 'value',
                                        'pitRef' => 'entity_ref2'  }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, @seq_no, basevol).to be false
  end

  it 'should return false if storage system do not have entities' do
    basevol = 'basevol'
    @response[:body] = JSON.generate([])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, @seq_no, basevol).to eq(false)
  end 

  it 'should return entity id if basevol matches given base volume ' do
    basevol = 'basevol'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'baseVol' => 'not_basevol',
                                        'key' => 'value',
                                        'pitRef' => 'entity_ref' },
                                      { 'id' => 'entity_id2',
                                        'baseVol' => basevol,
                                        'key' => 'value',
                                        'pitRef' => 'entity_ref2' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, @seq_no, basevol).to eq('entity_ref2')
  end

  it 'should raise RuntimeError if status code is not 200' do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { @method.call @sys_id, @cg_id , @seq_no, 'basevol' }.to raise_status_error(fail_message, @response)
  end
end

shared_examples 'a call for entity id based on storage system and by entity volume name' do |uri_suffix, tested_method|
  before(:each) do
    @sys_id = 'sys_id'
    @cg_id = 'cg_id'
    @seq_no = 'seq_no'
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/#{uri_suffix}"
    @method = @netapp_api.method(tested_method)
  end
  it 'should return false if name does not match given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => 'not_name2',
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/thin-volumes"
    @method = @netapp_api.method(tested_method)
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to be false
  end

  it 'should return false if storage system do not have entities' do
    name = 'name'
    @response[:body] = JSON.generate([])
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/#{uri_suffix}"
    Excon.stub(@expect_in_request, @response)
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/thin-volumes"
    @method = @netapp_api.method(tested_method)
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq(false)
  end

  it 'should return entity id if name matches given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => 'name1',
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/#{uri_suffix}"    
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => name,
                                        'key' => 'value' }
                                     ])
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/thin-volumes"
    @method = @netapp_api.method(tested_method)
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, name).to eq('entity_id2')
  end

  it 'should raise RuntimeError if status code is not 200' do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { @method.call @sys_id, 'name' }.to raise_status_error(fail_message, @response)
  end
end

shared_examples 'a call for entity id based on storage system and by entity view name' do |uri_suffix, tested_method|
  before(:each) do
    @sys_id = 'sys_id'
    @cg_id = 'cg_id'
    @expect_in_request[:url] = @url + "/devmgr/v2/storage-systems/#{@sys_id}/consistency-groups/#{@cg_id}/#{uri_suffix}"
    @method = @netapp_api.method(tested_method)
  end
  it 'should return false if name does not match given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => 'not_name2',
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, name).to be false
  end

  it 'should return false if storage system do not have entities' do
    name = 'name'
    @response[:body] = JSON.generate([])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, name).to eq(false)
  end

  it 'should return entity id if name matches given name' do
    name = 'name'
    @response[:body] = JSON.generate([{ 'id' => 'entity_id',
                                        'name' => 'not_name',
                                        'key' => 'value' },
                                      { 'id' => 'entity_id2',
                                        'name' => name,
                                        'key' => 'value' }
                                     ])
    Excon.stub(@expect_in_request, @response)
    expect(@method.call @sys_id, @cg_id, name).to eq('entity_id2')
  end

  it 'should raise RuntimeError if status code is not 200' do
    @response[:status] = 404
    Excon.stub(@expect_in_request, @response)
    expect { @method.call @sys_id, @cg_id, 'name' }.to raise_status_error(fail_message, @response)
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
    it_behaves_like 'a call for entity id based on storage system', 'storage-pools', :storage_pool_id do
      let(:fail_message) { 'Failed to get pool id' }
    end
  end

  context 'host_group_id' do
    it_behaves_like 'a call for entity id based on storage system', 'host-groups', :host_group_id do
      let(:fail_message) { 'Failed to get host group id' }
    end
  end

  context 'host_id' do
    it_behaves_like 'a call for entity id based on storage system', 'hosts', :host_id do
      let(:fail_message) { 'Failed to get host id' }
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

  context 'get_lun_mapping' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/volume-mappings'
    end
    it 'should raise Runtime Error if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_lun_mapping 'sys_id', 'lun' }.to raise_status_error('Failed to get lun mappings', @response)
    end
    it 'should return :absent if lun is not present' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_lun_mapping 'sys_id', 'lun').to eq(:absent)
    end
    context 'when lun is present' do
      before :each do
        @body[1]['lun'] = :lun
        @body[1].merge!('lun' => :lun,
                        'lunMappingRef' => 'lunMappingRef_value')
        @response[:body] = JSON.generate(@body)
        Excon.stub(@expect_in_request, @response)
      end
      it 'should return :present if status is set to true' do
        expect(@netapp_api.get_lun_mapping 'sys_id', 'lun', true).to eq(:present)
      end
      it 'should return lunMappingRef if status is set to false' do
        expect(@netapp_api.get_lun_mapping 'sys_id', 'lun', false).to eq('lunMappingRef_value')
      end
    end
  end
  context 'create_lun_mapping' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/volume-mappings' }
      let(:method_call) { @netapp_api.create_lun_mapping 'sys_id', 'map_id' }
      let(:fail_message) { 'Failed to create lun mapping' }
    end
  end
  context 'delete_lun_mapping' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/volume-mappings/map_id' }
      let(:method_call) { @netapp_api.delete_lun_mapping 'sys_id', 'map_id' }
      let(:fail_message) { 'Failed to delete lun mapping' }
    end
  end

  context 'create_mirror_members' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/async-mirrors/mg_id/pairs' }
      let(:method_call) { @netapp_api.create_mirror_members 'sys_id', 'mg_id', @request_body }
      let(:fail_message) { 'Failed to create mirror group members' }
    end
  end

  context 'delete_mirror_members' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/async-mirrors/mg_id/pairs/mem_id' }
      let(:method_call) { @netapp_api.delete_mirror_members 'sys_id', 'mg_id', 'mem_id' }
      let(:fail_message) { 'Failed to delete mirror group members' }
    end
  end

  context 'get_mirror_members' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/async-mirrors/mg_id/pairs'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_mirror_members 'sys_id', 'mg_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_mirror_members 'sys_id', 'mg_id' }.to raise_status_error('Failed to get mirror group members', @response)
    end
  end

  context 'get_consistency_groups' do
    it_behaves_like 'a call based on storage systems', 'consistency-groups' do
      let(:method_call) { @netapp_api.get_consistency_groups }
      let(:fail_message) { 'Failed to get consistency groups' }
    end
  end

  context 'create_consistency_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups' }
      let(:method_call) { @netapp_api.create_consistency_group 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create consistency group' }
    end
  end

  context 'delete_consistency_group' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id' }
      let(:method_call) { @netapp_api.delete_consistency_group 'sys_id', 'cg_id' }
      let(:fail_message) { 'Failed to remove consistency group' }
    end
  end

  context 'update_consistency_group' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id' }
      let(:method_call) { @netapp_api.update_consistency_group 'sys_id','cg_id', @request_body }
      let(:fail_message) { 'Failed to update consistency group' }
    end
  end

  context 'get_all_consistency_group_member_volumes' do
    it_behaves_like 'a call based on storage systems', 'consistency-groups/member-volumes' do
      let(:method_call) { @netapp_api.get_all_consistency_group_member_volumes }
      let(:fail_message) { 'Failed to get consistency groups member volumes' }
    end
  end

  context 'get_consistency_group_members' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/member-volumes'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_consistency_group_members 'sys_id', 'cg_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_consistency_group_members 'sys_id', 'cg_id' }.to raise_status_error('Failed to get consistency group member', @response)
    end
  end

  context 'add_consistency_group_member' do
    it_behaves_like 'a simple API call', :post, 201 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/member-volumes' }
      let(:method_call) { @netapp_api.add_consistency_group_member 'sys_id','cg_id', @request_body }
      let(:fail_message) { 'Failed to create consistency group member' }
    end
  end

  context 'get_consistency_group_member_volume' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/member-volumes/vol_id'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_consistency_group_member_volume 'sys_id', 'cg_id', 'vol_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_consistency_group_member_volume 'sys_id', 'cg_id', 'vol_id'}.to raise_status_error('Failed to get consistency group member volumes', @response)
    end
  end

  # context 'remove_consistency_group_member' do
  #   it_behaves_like 'a simple API call', :delete, 204 do
  #     let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/member-volumes/vol_id?retainRepositories=is_retainrepositories' }
  #    #let(:query) { 'retainRepositories=is_retainrepositories' }
  #     let(:method_call) { @netapp_api.remove_consistency_group_member 'sys_id', 'cg_id', 'vol_id', 'is_retainrepositories' }
  #     let(:fail_message) { 'Failed to delete consistency group member volumes' }
  #   end
  # end

  context 'get_consistency_group_id' do
    it_behaves_like 'a call for entity id based on storage system and by entity name', 'consistency-groups', :get_consistency_group_id  do
      let(:fail_message) { 'Failed to get consistency groups for specified storage system' }
    end
  end

  context 'get_consistency_group_snapshots' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/snapshots'
    end
    it 'should return parsed body if status code is 200' do
      @body = [{ 'id' => 'id_1',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3' ,
               'storagesystem' => 'sys_id'},
             { 'id' => 'id_2',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3',
               'storagesystem' => 'sys_id'
             }]
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_consistency_group_snapshots 'sys_id', 'cg_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_consistency_group_snapshots 'sys_id', 'cg_id' }.to raise_status_error('Failed to get snapshot group information', @response)
    end
  end

  context 'get_all_consistency_group_snapshots' do
    it 'should return parsed body if status code is 200' do
      
      cg_groups = [{'id' => '123456','label' => 'CGName1','storagesystem' => 'ssid1617'},
                  {'id' => '123789','label' => 'CGName2','storagesystem' => 'ssid1819'}] 

      expect(@netapp_api).to receive(:get_all_consistency_groups) { cg_groups }

      cg_snapshot_by_cg_id = { '123456' =>[ {'id' => '123','label' => 'CGSnap1','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '234','label' => 'CGSnap2','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'}],

         '123789' =>[ {'id' => '345','label' => 'CGSnap3','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'},
        {'id' => '456','label' => 'CGSnap4','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'}]
      }
      cg_groups.each do |curcg|
          expect(@netapp_api).to receive(:get_consistency_group_snapshots).with(curcg['storagesystem'],
                                                                      curcg['id']) { cg_snapshot_by_cg_id[curcg['id']] }
      end
      cg_snap_response = [ {'id' => '123','label' => 'CGSnap1','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '234','label' => 'CGSnap2','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '345','label' => 'CGSnap3','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'},
        {'id' => '456','label' => 'CGSnap4','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'}]
      
      expect(@netapp_api.get_all_consistency_group_snapshots).to eq(cg_snap_response)
    end
  end

  context 'get_oldest_sequence_no' do
    it 'should return parsed body if status code is 200' do
      sys_id = 'ictm-aaol-pp2_18-19'
      cg_name = 'CG_CFW_Upgrade'
      cg_id = '2A00000060080E50001F6D3800871291565FA14E'
      seq_no = 2
      expect(@netapp_api).to receive(:get_consistency_group_id).with(sys_id, cg_name) { cg_id }
      cg_snapshot_by_cg_id = { '2A00000060080E50001F6D3800871291565FA14E' =>[ {'id' => '123', 'pitSequenceNumber'=>2,'label' => 'CGSnap1','storagesystem' => 'ictm-aaol-pp2_18-19','consistencygroup'=>'CG_CFW_Upgrade'},
        {'id' => '234', 'pitSequenceNumber'=>3,'label' => 'CGSnap2','storagesystem' => 'ictm-aaol-pp2_18-19','consistencygroup'=>'CG_CFW_Upgrade'}],

         '123789' =>[ {'id' => '345', 'pitSequenceNumber'=>3,'label' => 'CGSnap3','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'},
        {'id' => '456', 'pitSequenceNumber'=>4,'label' => 'CGSnap4','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'}]
      }
      expect(@netapp_api).to receive(:get_consistency_group_snapshots).with(sys_id, cg_id) { cg_snapshot_by_cg_id[cg_id] }
      expect(@netapp_api.get_oldest_sequence_no 'ictm-aaol-pp2_18-19', 'CG_CFW_Upgrade').to eq(seq_no)
    end
  end

  context 'create_consistency_group_snapshot' do
    before :each do
      @expected_result = [{"id"=>"id_1", "first_key"=>"first_value1", "second_key"=>"second_value2", "third_key"=>"third_value3"}, {"id"=>"id_2", "first_key"=>"first_value1", "second_key"=>"second_value2", "third_key"=>"third_value3"}]
    end
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/snapshots/' }
      let(:method_call) { @netapp_api.create_consistency_group_snapshot 'sys_id', 'cg_id', @request_body }
      let(:fail_message) { 'Failed to create consistency group snapshot' }
    end
  end

  context 'remove_oldest_consistency_group_snapshot' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/snapshots/seq_no' }
      let(:method_call) { @netapp_api.remove_oldest_consistency_group_snapshot 'sys_id', 'cg_id', 'seq_no' }
      let(:fail_message) { 'Failed to remove consistency group snapshot' }
    end
  end

  context 'rollback_consistency_group' do
    it_behaves_like 'a simple API call', :post, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/snapshots/seq_no/rollback' }
      let(:method_call) { @netapp_api.rollback_consistency_group 'sys_id', 'cg_id', 'seq_no' }
      let(:fail_message) { 'Failed to rollback consistency group snapshot' }
    end
  end

  context 'get_consistency_group_snapshots_by_seqno' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/snapshots/seq_no'
    end
    it 'should return parsed body if status code is 200' do
      @body = [{ 'id' => 'id_1',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3' ,
               'storagesystem' => 'sys_id'},
             { 'id' => 'id_2',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3',
               'storagesystem' => 'sys_id'
             }]
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_consistency_group_snapshots_by_seqno 'sys_id', 'cg_id', 'seq_no').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_consistency_group_snapshots_by_seqno 'sys_id', 'cg_id', 'seq_no' }.to raise_status_error('Failed to get snapshot group information', @response)
    end
  end

  context 'create_consistency_group_snapshot_view' do
    it_behaves_like 'a simple API call', :post, 201 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/views' }
      let(:method_call) { @netapp_api.create_consistency_group_snapshot_view 'sys_id', 'cg_id', @request_body }
      let(:fail_message) { 'Failed to create consistency group view' }
    end
  end

  context 'get_pit_id_by_volume_id' do
    it_behaves_like 'a call for entity id based on storage system and by entity base volume', 'snapshots', :get_pit_id_by_volume_id  do
      let(:fail_message) { 'Failed to get snapshot volume information' }
    end
  end

  context 'get_volume_id' do
    it_behaves_like 'a call for entity id based on storage system and by entity volume name', 'volumes', :get_volume_id  do
      let(:fail_message) { 'Failed to get Volumes'  or 'Failed to get thin Volumes'}
    end
  end

  context 'delete_consistency_group_snapshot_view' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/views/view_id' }
      let(:method_call) { @netapp_api.delete_consistency_group_snapshot_view 'sys_id', 'cg_id', 'view_id' }
      let(:fail_message) { 'Failed to remove consistency group snapshot view' }
    end
  end

  context 'get_consistency_group_snapshot_view_id' do
    it_behaves_like 'a call for entity id based on storage system and by entity view name', 'views', :get_consistency_group_snapshot_view_id  do
      let(:fail_message) { 'Failed to get consistency groups snapshot views for specified storage system'}
    end
  end

  context 'get_consistency_group_views' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/consistency-groups/cg_id/views'
    end
    it 'should return parsed body if status code is 200' do
      @body = [{ 'id' => 'id_1',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3' ,
               'storagesystem' => 'sys_id'},
             { 'id' => 'id_2',
               'first_key' => 'first_value1',
               'second_key' => 'second_value2',
               'third_key' => 'third_value3',
               'storagesystem' => 'sys_id'
             }]
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_consistency_group_views 'sys_id', 'cg_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_consistency_group_views 'sys_id', 'cg_id'}.to raise_status_error('Failed to get snapshot view information', @response)
    end
  end

  context 'get_all_consistency_group_views' do
    it 'should return parsed body if status code is 200' do
      
      cg_groups = [{'id' => '123456','label' => 'CGName1','storagesystem' => 'ssid1617'},
                  {'id' => '123789','label' => 'CGName2','storagesystem' => 'ssid1819'}] 

      expect(@netapp_api).to receive(:get_all_consistency_groups) { cg_groups }

      cg_views_by_cg_id = { '123456' =>[ {'id' => '123','label' => 'CGView1','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '234','label' => 'CGView2','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'}],

         '123789' =>[ {'id' => '345','label' => 'CGView3','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'},
        {'id' => '456','label' => 'CGView4','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'}]
      }
      cg_groups.each do |curcg|
          expect(@netapp_api).to receive(:get_consistency_group_views).with(curcg['storagesystem'],
                                                                      curcg['id']) { cg_views_by_cg_id[curcg['id']] }
      end
      cg_views_response = [ {'id' => '123','label' => 'CGView1','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '234','label' => 'CGView2','storagesystem' => 'ssid1617','consistencygroup'=>'CGName1'},
        {'id' => '345','label' => 'CGView3','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'},
        {'id' => '456','label' => 'CGView4','storagesystem' => 'ssid1819','consistencygroup'=>'CGName2'}]
      
      expect(@netapp_api.get_all_consistency_group_views).to eq(cg_views_response)
    end
  end
  
  context 'get_firmware_files' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/firmware/cfw-files/'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_firmware_files).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_firmware_files}.to raise_status_error('Failed to get uploaded firmware file list', @response)
    end
  end

  context 'delete_firmware_file' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/firmware/upload/file' }
      let(:method_call) { @netapp_api.delete_firmware_file 'file' }
      let(:fail_message) { 'Failed to delete firmware file' }
    end
  end

  context 'check_firmware_compatibility' do
    before(:each) do
      @expect_in_request.merge!( :method => :post,
                                 :url => @url + '/devmgr/v2/firmware/compatibility-check/'
        )
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.check_firmware_compatibility @request_body).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.check_firmware_compatibility @request_body}.to raise_status_error('Failed to check compatibility for upgrade firmware controller.', @response)
    end
  end

  context 'upgrade_controller_firmware' do
    before(:each) do
      @expect_in_request.merge!( :method => :post,
                                 :url => @url + '/devmgr/v2/storage-systems/sys_id/cfw-upgrade/'
        )
    end
    it 'should return parsed body if status code is 202' do
      @response[:status] = 202
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.upgrade_controller_firmware 'sys_id', @request_body).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 202' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.upgrade_controller_firmware 'sys_id', @request_body}.to raise_status_error('Failed to upgrade firmware controller', @response)
    end
  end

  context 'activate_controller_firmware' do
    before(:each) do
      @expect_in_request.merge!( :method => :post,
                                 :url => @url + '/devmgr/v2/storage-systems/sys_id/cfw-upgrade/activate'
        )
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.activate_controller_firmware 'sys_id', @request_body).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.activate_controller_firmware 'sys_id', @request_body}.to raise_status_error('Failed to activate firmware controller', @response)
    end
  end

  context 'get_web_proxy_update' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/upgrade'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_web_proxy_update).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_web_proxy_update}.to raise_status_error('Failed to web proxy upgrade detail', @response)
    end
  end

  context 'reload_web_proxy_update' do
    before(:each) do
      @expect_in_request.merge!( :method => :post,
                                 :url => @url + '/devmgr/v2/upgrade/reload'
        )
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.reload_web_proxy_update).to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.reload_web_proxy_update}.to raise_status_error('Failed to reload web proxy updates', @response)
    end
  end

  context 'get_events' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/events'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_events)
    end
  end

  context 'get_flash_cache' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/flash-cache'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_flash_cache 'sys_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_flash_cache 'sys_id'}.to raise_status_error('Failed to get flash cache', @response)
    end
  end

  context 'get_drives' do
    before(:each) do
      @expect_in_request[:url] = @url + '/devmgr/v2/storage-systems/sys_id/drives'
    end
    it 'should return parsed body if status code is 200' do
      Excon.stub(@expect_in_request, @response)
      expect(@netapp_api.get_drives 'sys_id').to eq(@body)
    end
    it 'should raise RuntimeError if status code is not 200' do
      @response[:status] = 404
      Excon.stub(@expect_in_request, @response)
      expect { @netapp_api.get_drives 'sys_id'}.to raise_status_error('Failed to get drives', @response)
    end
  end

  context 'suspend_flash_cache' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache/suspend' }
      let(:method_call) { @netapp_api.suspend_flash_cache 'sys_id' }
      let(:fail_message) { 'Failed to suspend flash cache' }
    end
  end

  context 'resume_flash_cache' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache/resume' }
      let(:method_call) { @netapp_api.resume_flash_cache 'sys_id' }
      let(:fail_message) { 'Failed to resume flash cache' }
    end
  end

  context 'create_flash_cache' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache' }
      let(:method_call) { @netapp_api.create_flash_cache 'sys_id', @request_body }
      let(:fail_message) { 'Failed to create flash cache' }
    end
  end

  context 'delete_flash_cache' do
    it_behaves_like 'a simple API call', :delete, 204 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache' }
      let(:method_call) { @netapp_api.delete_flash_cache 'sys_id'}
      let(:fail_message) { 'Failed to delete flash cache' }
    end
  end

  context 'update_flash_cache' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache/configure' }
      let(:method_call) { @netapp_api.update_flash_cache 'sys_id', @request_body }
      let(:fail_message) { 'Failed to update flash cache' }
    end
  end

  context 'flash_cache_add_drives' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache/addDrives' }
      let(:method_call) { @netapp_api.flash_cache_add_drives 'sys_id', @request_body }
      let(:fail_message) { 'Failed to add drives to flash cache' }
    end
  end

  context 'flash_cache_remove_drives' do
    it_behaves_like 'a simple API call', :post, 200 do
      let(:uri) { '/devmgr/v2/storage-systems/sys_id/flash-cache/removeDrives' }
      let(:method_call) { @netapp_api.flash_cache_remove_drives 'sys_id', @request_body }
      let(:fail_message) { 'Failed to remove drives to flash cache' }
    end
  end
  
  
end
