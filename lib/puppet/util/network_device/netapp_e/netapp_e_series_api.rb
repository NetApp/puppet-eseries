require 'rubygems'
require 'json'
require 'excon'

class NetApp
  class ESeries
    class Api
      attr_reader :url
      def initialize(user, password, url, verify_ssl = true, connect_timeout = nil)
        @user = user
        @password = password
        @url = url
        @connect_timeout = connect_timeout

        Excon.defaults[:ssl_verify_peer] = verify_ssl
      end

      def login
        body = { :userId => @user, :password => @password }.to_json
        response = request(:post, '/devmgr/utils/login', body)
        fail "Login failed. HTTP error- #{response.status}" if response.status != 200
        @cookie = response.headers['Set-Cookie'].split(';').first
      end

      def get_storage_systems
        response = request(:get, '/devmgr/v2/storage-systems/')
        status(response, 200, 'Could not get info about storage systems')
        JSON.parse(response.body)
      end

      def get_storage_systems_id
        ids = []
        response = get_storage_systems
        response.each do |storage_system|
          ids << storage_system['id']
        end
        ids
      end

      def get_network_interfaces
        # array of arrays
        all_interfaces = []

        # we can have many storage_systems defined on webproxy
        ids = get_storage_systems_id
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/configuration/ethernet-interfaces/")
            status(response, 200, 'Could not get network interfaces information')
            system_storage_interfaces =  JSON.parse(response.body)

            # add sys_id to interface hash
            storage_system = { 'storagesystem' => sys_id }
            system_storage_interfaces.map! { |interface| interface.merge(storage_system) }

            all_interfaces << system_storage_interfaces
          end
          all_interfaces = all_interfaces.reduce(:concat)
        end
        all_interfaces
      end

      def update_ethernet_interface(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/configuration/ethernet-interfaces/", request_body.to_json)
        status(response, 200, 'Could not update network interfaces')
      end

      # Call storage system API /devmgr/v2/storage-systems to add a new storage system
      def create_storage_system(request_body)
        response = request(:post, '/devmgr/v2/storage-systems', request_body.to_json)
        status(response, 201, 'Storage Creation Failed')
      end

      # Call storage system API /devmgr/v2/storage-systems/{storage-system-id} to remove the storage system
      def delete_storage_system(sys_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}")
        status(response, 204, 'Storage Deletion Failed')
      end

      def update_storage_system(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}", request_body.to_json)
        status(response, 200, 'Could not update storage system')
      end

      def get_passwords_status(sys_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/passwords/")
        status(response, 200, 'Could not get information about storage passwords')
        passwords = JSON.parse(response.body)
        passwords[:storagesystem] = sys_id
        passwords
      end

      # Call storage system API /devmgr/v2/{storage-system-id}/passwords to change the password of the storage system
      def change_password(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/passwords/", request_body.to_json)
        status(response, 204, 'Password Update Failed')
      end

      def get_hosts
        ids = get_storage_systems_id
        all_hosts = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/hosts")
            status(response, 200, 'Could not get hosts information')
            hosts = JSON.parse(response.body)

            # add sys_id to pool hash
            storage_system = { 'storagesystem' => sys_id }
            hosts.map! { |host| host.merge(storage_system) }

            # change address key to port key, find initiator refs
            mappings = { 'address' => 'port' }
            hosts.each do |host|
              host['hostSidePorts'].each do |port|
                port.keys.each { |k| port[mappings[k]] = port.delete(k) if mappings[k] }
              end

              host['initiators_ref_numbers'] = []
              host['initiators'].each do |ini|
                # add initiatiors refs numbers property
                host['initiators_ref_numbers'] << ini['initiatorRef']
              end
            end

            all_hosts << hosts
          end
          all_hosts = all_hosts.reduce(:concat)
        end
        all_hosts
      end

      # Call host API /devmgr/v2/{storage-system-id}/hosts to add a host
      def create_host(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/hosts", request_body.to_json)
        status(response, 201, 'Failed to create host')
      end

      def update_host(sys_id, host_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/hosts/#{host_id}", request_body.to_json)
        status(response, 204, "Failed update host #{host_id}")
      end

      # Call host API /devmgr/v2/{storage-system-id}/hosts/{host-id} to remove a host
      def delete_host(sys_id, host_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/hosts/#{host_id}")
        status(response, 204, 'Failed to delete host')
      end

      def get_host_groups
        ids = get_storage_systems_id
        all_host_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/host-groups")
            status(response, 200, 'Could not get host groups information')
            host_groups = JSON.parse(response.body)
            # add sys_id to pool hash
            storage_system = { 'storagesystem' => sys_id }
            host_groups.map! { |hg| hg.merge(storage_system) }
            all_host_groups << host_groups
          end
          all_host_groups = all_host_groups.reduce(:concat)
        end
        all_host_groups
      end

      # Call host-group API /devmgr/v2/{storage-system-id}/host-groups to add a host-group
      def create_host_group(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/host-groups", request_body.to_json)
        status(response, 201, 'Failed to create host group')
      end

      # Call host-group API /devmgr/v2/{storage-system-id}/host-groups/{host-group-id} to remove a host-group
      def delete_host_group(sys_id, hg_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/host-groups/#{hg_id}")
        status(response, 204, 'Failed to delete host group')
      end

      def get_storage_pools
        ids = get_storage_systems_id
        all_storage_pools = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/storage-pools/")
            status(response, 200, 'Failed to get storage pool information')
            storage_pools =  JSON.parse(response.body)

            # add sys_id to pool hash
            storage_system = { 'storagesystem' => sys_id }
            storage_pools.map! { |pool| pool.merge(storage_system) }

            all_storage_pools << storage_pools
          end
          all_storage_pools = all_storage_pools.reduce(:concat)
        end
        all_storage_pools
      end

      # Call storage-pool API /devmgr/v2/{storage-system-id}/storage-pools to create a volume group or a disk pool.
      # Disk pool can be created only with raid level 'raidDiskPool'.
      def create_storage_pool(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/storage-pools", request_body.to_json)
        status(response, 200, 'Failed to create storage pool')
      end

      # Call storage-pool API /devmgr/v2/{storage-system-id}/storage-pools/{storage-pool-id} to delete a volume group or a disk pool.
      def delete_storage_pool(sys_id, pool_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/storage-pools/#{pool_id}")
        status(response, 204, 'Failed to delete storage pool')
      end

      def get_volumes
        ids = get_storage_systems_id
        all_volumes = []
        if not ids.empty?
          ids.each do |sys_id|
            storage_system = { 'storagesystem' => sys_id }

            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/volumes")
            status(response, 200, 'Failed to get volumes information')
            volumes =  JSON.parse(response.body)

            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/thin-volumes")
            status(response, 200, 'Failed to get thin-volumes information')
            thinvol = JSON.parse(response.body)

            volumes.map! { |vol| vol.merge(storage_system) }
            thinvol.map! { |vol| vol.merge(storage_system) }

            all_volumes << volumes
            all_volumes << thinvol
          end
          all_volumes = all_volumes.reduce(:concat)
        end
        all_volumes
      end

      def get_lun_mapping(sys_id, lun, status = true)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/volume-mappings")
        status(response, 200, 'Failed to get lun mappings')
        mappings = JSON.parse(response.body)

        mappings.each do |vmap|
          if lun == vmap['lun'].to_s
            if status
              return :present
            else
              return vmap['lunMappingRef']
            end
          end
        end

        :absent
      end

      def create_lun_mapping(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/volume-mappings", request_body.to_json)
        status(response, 200, 'Failed to create lun mapping')
      end

      def delete_lun_mapping(sys_id, map_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/volume-mappings/#{map_id}")
        status(response, 204, 'Failed to delete lun mapping')
      end

      # Call volume API /devmgr/v2/{storage-system-id}/volumes to create a new volume.
      def create_volume(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/volumes", request_body.to_json)
        status(response, 200, 'Failed to create volume')
      end

      # Call volume API /devmgr/v3/{storage-system-id}/volumes/{volume-id} to delete a volume.
      def delete_volume(sys_id, vol_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/volumes/#{vol_id}")
        status(response, 204, 'Failed to delete volume')
      end

      # Call thin volume API /devmgr/v2/{storage-system-id}/thin-volumes to create a thin volume
      def create_thin_volume(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/thin-volumes", request_body.to_json)
        status(response, 200, 'Failed to create thin volume')
      end

      # Call thin volume API /devmgr/v2/{storage-system-id}/thin-volumes/{thin-volume-id} to delete a thin volume
      def delete_thin_volume(sys_id, volume_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/thin-volumes/#{volume_id}")
        status(response, 204, 'Failed to delete thin volume')
      end

      # Get the storage-pool-id using storage-system-ip and storage-pool name
      def storage_pool_id(sys_id, name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/storage-pools")
        status(response, 200, 'Failed to get pool id')
        storage_pools = JSON.parse(response.body)
        storage_pools.each do |pool|
          return pool['id'] if pool['label'] == name
        end
        nil
      end

      # Get the host-group-id using storage-system-ip and host-group name
      def host_group_id(sys_id, name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/host-groups")
        status(response, 200, 'Failed to get host group id')
        host_groups = JSON.parse(response.body)
        host_groups.each do |host_group|
          return host_group['id'] if host_group['label'] == name
        end
        nil
      end

      # Get the host-id using storage-system-ip and host name
      def host_id(sys_id, name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/hosts")
        status(response, 200, 'Failed to get host id')
        hosts = JSON.parse(response.body)
        hosts.each do |host|
          return host['id'] if host['label'] == name
        end
        nil
      end

      def get_snapshot_groups
        ids = get_storage_systems_id
        all_snapshot_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-groups/")
            status(response, 200, 'Failed to get snapshot group information')
            snapshot_groups =  JSON.parse(response.body)

            # add sys_id to pool hash
            storage_system = { 'storagesystem' => sys_id }
            snapshot_groups.map! { |group| group.merge(storage_system) }

            all_snapshot_groups << snapshot_groups
          end
          all_snapshot_groups = all_snapshot_groups.reduce(:concat)
        end
        all_snapshot_groups
      end

      def create_snapshot_group(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-groups", request_body.to_json)
        status(response, 200, 'Failed to creat snapshot group')
      end

      def delete_snapshot_group(sys_id, snapshot_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-groups/#{snapshot_id}")
        status(response, 204, 'Failed to delete snapshot group')
      end

      def update_snapshot_group(sys_id, snapshot_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-groups/#{snapshot_id}", request_body.to_json)
        status(response, 200, 'Failed to update snapshot group')
      end

      def get_snapshot_volumes
        ids = get_storage_systems_id
        all_snapshot_volumes = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-volumes")
            status(response, 200, 'Could not get snapshot volumes information')
            volumes = JSON.parse(response.body)
            # add sys_id to volume hash
            storage_system = { 'storagesystem' => sys_id }
            volumes.map! { |hg| hg.merge(storage_system) }
            all_snapshot_volumes << volumes
          end
          all_snapshot_volumes = all_snapshot_volumes.reduce(:concat)
        end
        all_snapshot_volumes
      end

      def create_snapshot_volume(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-volumes", request_body.to_json)
        status(response, 200, 'Failed to create snapshot volume')
      end

      def delete_snapshot_volume(sys_id, sv_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-volumes/#{sv_id}")
        status(response, 204, 'Failed to delete snapshot volume')
      end

      def update_snapshot_volume(sys_id, sv_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-volumes/#{sv_id}", request_body.to_json)
        status(response, 200, 'Failed to update snapshot volume')
      end

      def volume_copy_id(sys_id, source, target)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/volume-copy-jobs")
        status(response, 200, 'Failed to get volume copy jobs')
        volume_copies = JSON.parse(response.body)
        volume_copies.each do |vc|
          return vc['id'] if vc['sourceVolume'] == source and vc['targetVolume'] == target
        end
        false
      end

      def create_volume_copy(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/volume-copy-jobs", request_body.to_json)
        status(response, 200, 'Failed to create volume copy')
      end

      def delete_volume_copy(sys_id, vc_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/volume-copy-jobs/#{vc_id}")
        status(response, 204, 'Failed to delete volume copy jobs')
      end

      def create_snapshot_image(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-images", request_body.to_json)
        status(response, 200, 'Failed to create snapshot image')
      end

      def get_snapshot_group_id(sys_id, name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/snapshot-groups")
        status(response, 200, 'Failed to get snapshot group id')
        snapshot_groups = JSON.parse(response.body)
        snapshot_groups.each do |sg|
          return sg['id'] if sg['label'] == name
        end
        false
      end

      def get_mirror_groups
        ids = get_storage_systems_id
        all_mirror_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors")
            status(response, 200, 'Failed to get mirror groups')
            m_groups = JSON.parse(response.body)
            # add sys_id to volume hash
            storage_system = { 'storagesystem' => sys_id }
            m_groups.map! { |mg| mg.merge(storage_system) }
            all_mirror_groups << m_groups
          end
          all_mirror_groups = all_mirror_groups.reduce(:concat)
        end
        all_mirror_groups
      end

      def create_mirror_group(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors", request_body.to_json)
        status(response, 200, 'Failed to create mirror group')
      end

      def delete_mirror_group(sys_id, mg_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors/#{mg_id}")
        status(response, 204, 'Failed to delete mirror group')
      end

      def update_mirror_group(sys_id, mg_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors/#{mg_id}", request_body.to_json)
        status(response, 200, 'Failed to update mirror group')
      end

      def get_mirror_members(sys_id, mg_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors/#{mg_id}/pairs")
        status(response, 200, 'Failed to get mirror group members')
        JSON.parse(response.body)
      end

      def create_mirror_members(sys_id, mg_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors/#{mg_id}/pairs", request_body.to_json)
        status(response, 200, 'Failed to create mirror group members')
      end

      def delete_mirror_members(sys_id, mg_id, mem_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/async-mirrors/#{mg_id}/pairs/#{mem_id}")
        status(response, 204, 'Failed to delete mirror group members')
      end

      def post_key_value(key, value)
        response = request(:post, "/devmgr/v2/key-values/#{key}", value)
        status(response, 200, 'Failed to add key/value pair')
      end

      private

      # Determine the status of the response
      def status(response, expected_status_code, failure_message)
        if response.status == expected_status_code
          true
        else
          fail("#{failure_message}. Response: #{response.status} #{response.reason_phrase} #{response.body}")
        end
      end

      # Make a call to the web proxy
      def request(method, path, body = nil)
        Excon.send(method, @url, :path => path, :headers => web_proxy_headers, :body => body, :connect_timeout => @connect_timeout)
      end

      # Set headers for web proxy.
      def web_proxy_headers
        { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'cookie' => @cookie }
      end
    end
  end
end
