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

      def get_storage_system(sys_id)
        storage_system_details = []
        response = get_storage_systems
        response.each do |storage_system|
          if storage_system['id'] == sys_id
            storage_system_details << storage_system
            return storage_system_details
          end
        end
        false
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
        response = request(:post, "/devmgr/v2/key-values/#{key}?value=#{value}", value)
        status(response, 200, 'Failed to add key/value pair')
      end

      #Call Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups to get all consistency group
      def get_consistency_groups
        ids = get_storage_systems_id
        all_consistency_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups")
            status(response, 200, 'Failed to get consistency groups')
            if response.status == 200
              c_groups = JSON.parse(response.body)
              storage_system = { 'storagesystem' => sys_id }
              c_groups.map! { |cg| cg.merge(storage_system) }
              all_consistency_groups << c_groups
            end
          end
          all_consistency_groups = all_consistency_groups.reduce(:concat)
        end
        all_consistency_groups
      end

      #Call Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups to get all consistency group
      def get_all_consistency_groups
        ids = get_storage_systems_id
        all_consistency_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups")
            status(response, 200, 'Failed to get consistency groups')
            if response.status == 200
              c_groups = JSON.parse(response.body)
              storage_system = { 'storagesystem' => sys_id }
              c_groups.map! { |cg| cg.merge(storage_system) }
              all_consistency_groups << c_groups
            end
          end
          all_consistency_groups = all_consistency_groups.reduce(:concat)
        end
        all_consistency_groups
      end

      #Call Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups to create new consistency group
      def create_consistency_group(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups", request_body.to_json)
        status(response, 200, 'Failed to create consistency group')
      end

      #Call Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id} to delete consistency group
      def delete_consistency_group(sys_id, cg_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}")
        status(response, 204, 'Failed to remove consistency group')
      end

      #Call Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id} to delete consistency group
      def update_consistency_group(sys_id, cg_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}", request_body.to_json)
        status(response, 200, 'Failed to update consistency group')
      end

      #Call Consistency-Group member-volumes API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups
      #To get all consistency group member volumes
      #Unused Method
      def get_all_consistency_group_member_volumes
        ids = get_storage_systems_id
        all_member_volumes_groups = []
        if not ids.empty?
          ids.each do |sys_id|
            response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/member-volumes")
            status(response, 200, 'Failed to get consistency groups member volumes')
            if response.status == 200
              m_volumes = JSON.parse(response.body)
              storage_system = { 'storagesystem' => sys_id }
              m_volumes.map! { |mvg| mvg.merge(storage_system) }
              all_member_volumes_groups << m_volumes
            end
          end
          all_member_volumes_groups = all_member_volumes_groups.reduce(:concat)
        end
        all_member_volumes_groups
      end

      #Call Consistency-Group member-volumes API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes
      #To get perticular consistency group member 
      def get_consistency_group_members(sys_id, cg_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes")
        status(response, 200, 'Failed to get consistency group member')
        JSON.parse(response.body)
      end

      #Call Consistency-Group member-volumes API /devmgr/v2/storage-systems/{system-id}/consistency-groups/{cg-id}/member-volumes/
      #To create new member in consistency group
      def add_consistency_group_member(sys_id, cg_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes", request_body.to_json)
        status(response, 201, 'Failed to create consistency group member')
      end

      #Call Consistency-Group member-volumes API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes
      #To get perticular consistency group member volume
      def get_consistency_group_member_volume(sys_id, cg_id, vol_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes/#{vol_id}")
        status(response, 200, 'Failed to get consistency group member volumes')
        JSON.parse(response.body)
      end

      #Call Consistency-Group API member-volumes API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes/#{vol_id}
      #To delete consistency group member volumes
      def remove_consistency_group_member(sys_id, cg_id, vol_id, is_retainrepositories)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/member-volumes/#{vol_id}?retainRepositories=#{is_retainrepositories}")
        status(response, 204, 'Failed to delete consistency group member volumes')
      end

      #Get Consistency Group id by Consistency Group name
      def get_consistency_group_id(sys_id, cg_name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups")
        status(response, 200, 'Failed to get consistency groups for specified storage system')
        consistency_groups = JSON.parse(response.body)
        consistency_groups.each do |cg|
          return cg['id'] if cg['name'] == cg_name
        end
        false
      end

      #Get all snapshots of a Consistency Group
      def get_consistency_group_snapshots(sys_id,cg_id)
        all_snapshots = []
		    response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots")
        status(response, 200, 'Failed to get snapshot group information')
        if response.status == 200
          cg_snapshots =  JSON.parse(response.body)
          storage_system = { 'storagesystem' => sys_id }
          cg_snapshots.map! { |group| group.merge(storage_system) }
          
          all_snapshots << cg_snapshots
  	    end
        all_snapshots = all_snapshots.reduce(:concat)
      end

      #Get all snapshots of consistency groups of all storage systems
      def get_all_consistency_group_snapshots
        all_snapshots = []
        consistency_groups =  get_all_consistency_groups
        consistency_groups.each do |data|
          cg_id=data['id']
          storage_system=data['storagesystem']
          cg_snapshots =  get_consistency_group_snapshots(storage_system,cg_id)
          all_snapshots << cg_snapshots
        end
        all_snapshots = all_snapshots.reduce(:concat)
      end
      
      #Get oldest snapshot number of a consistency group
      def get_oldest_sequence_no(sys_id,cg_name)
        cg_id = get_consistency_group_id(sys_id,cg_name)
        cg_snapshots = get_consistency_group_snapshots(sys_id,cg_id)
        oldest_seq_no = 0
	      cg_snapshots.each do |data|
		    if ((oldest_seq_no > (data['pitSequenceNumber']).to_i) || oldest_seq_no == 0 )
                	oldest_seq_no = (data['pitSequenceNumber']).to_i
              	end
	      end
        oldest_seq_no
      end      

      # Call create Consistency group snapshot API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/ 
      # To create consistency group snapshot
      def create_consistency_group_snapshot(sys_id, cg_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/", request_body.to_json)
        status(response, 200, 'Failed to create consistency group snapshot')
        JSON.parse(response.body)   
      end

      # Call remove Consistency-Group member API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}
      # To remove consistency group snapshot
      def remove_oldest_consistency_group_snapshot(sys_id, cg_id, seq_no)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}")
        status(response, 204, 'Failed to remove consistency group snapshot')
      end

      # Call rollback Consistency-Group API /devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}/rollback
      # To rollback consistency group to a snapshot
      def rollback_consistency_group(sys_id, cg_id, seq_no)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}/rollback")
        status(response, 204, 'Failed to rollback consistency group snapshot')
      end

      # Call create snapshot view(s) API /storage-systems/{system-id}/consistency-groups/{cg-id}/views
      # To create a volume from consistency group snapshot
      def create_consistency_group_snapshot_view(sys_id, cg_id, request_body)
 	      response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/views", request_body.to_json)
        status(response, 201, 'Failed to create consistency group view')
      end

      # Get all snapshots of a Consistency Group by snapshot sequence Number
      def get_consistency_group_snapshots_by_seqno(sys_id, cg_id, seq_no)
        all_snapshots = []
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}")
        status(response, 200, 'Failed to get snapshot group information')
        if response.status == 200
          cg_snapshots =  JSON.parse(response.body)
          storage_system = { 'storagesystem' => sys_id }
          cg_snapshots.map! { |group| group.merge(storage_system) }
          all_snapshots << cg_snapshots
        end
        all_snapshots = all_snapshots.reduce(:concat)
      end

      #Get Pit id from Consistency Group Snapshot by Volume Id
      def get_pit_id_by_volume_id(sys_id, cg_id, seq_no, volume_id)
	      response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/snapshots/#{seq_no}")
        status(response, 200, 'Failed to get snapshot volume information')
        if response.status == 200
          snapshots = JSON.parse(response.body)
          snapshots.each do |sp|
  	         return sp['pitRef'] if sp['baseVol'] == volume_id
          end
        end
        false
      end

      #Get volume id by volume name
      def get_volume_id(sys_id,volume_name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/volumes")
        status(response, 200, 'Failed to get Volumes')
        volumes = JSON.parse(response.body)
        volumes.each do |vm|
 	          return vm['id'] if vm['name'] == volume_name
      	end
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/thin-volumes")
        status(response, 200, 'Failed to get thin Volumes')
        volumes = JSON.parse(response.body)
        volumes.each do |vm|
            return vm['id'] if vm['name'] == volume_name
        end
      	false
      end

      #Delete existing Snapshot View
      def delete_consistency_group_snapshot_view(sys_id, cg_id, view_id)
	      response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/views/#{view_id}")
        status(response, 204, 'Failed to remove consistency group snapshot view')
      end

      #Get view id of snapshot of consistency group
      def get_consistency_group_snapshot_view_id(sys_id, cg_id, view_name)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/views")
        status(response, 200, 'Failed to get consistency groups snapshot views for specified storage system')
        views = JSON.parse(response.body)
        views.each do |vw|
          return vw['id'] if vw['name'] == view_name
        end
        false
      end

      #Get all snapshot views associated consistency group 
      def get_consistency_group_views(sys_id, cg_id)
        all_views = []
		    response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/consistency-groups/#{cg_id}/views")
        status(response, 200, 'Failed to get snapshot view information')
        if response.status == 200
          cg_views =  JSON.parse(response.body)
          storage_system = { 'storagesystem' => sys_id }
          cg_views.map! { |group| group.merge(storage_system) }
          all_views << cg_views
  	    end
        all_views = all_views.reduce(:concat)
      end

      #Get all views of snapshots of consistency groups of all storage systems
      def get_all_consistency_group_views
        all_views = []
        consistency_groups =  get_all_consistency_groups
        consistency_groups.each do |data|
          cg_id=data['id']
          storage_system=data['storagesystem']
          cg_views =  get_consistency_group_views(storage_system,cg_id)
          all_views << cg_views
        end
        all_views = all_views.reduce(:concat)
      end

      #Get all uploaded firmware files
      def get_firmware_files
        response = request(:get, "/devmgr/v2/firmware/cfw-files/")
        status(response, 200, 'Failed to get uploaded firmware file list')
        JSON.parse(response.body)
      end

      #Upload a new firmware file
      def upload_firmware_file(file,is_validate)
        
        method    = :post
        path      = "/devmgr/v2/firmware/upload/?validate=#{is_validate}"
        boundary  = rand 1000000000000000

        body      = ''        
        body << "--#{boundary}" << Excon::CR_NL
        body << %{Content-Disposition: form-data; name="firmwareFile"; filename="#{File.basename(file)}"} << Excon::CR_NL
        body << 'Content-Type: application/x-gtar' << Excon::CR_NL
        body << Excon::CR_NL
        body << File.binread(file)
        body << Excon::CR_NL
        body << "--#{boundary}--" << Excon::CR_NL

        url_request = { :headers => { 'Content-Type' => %{multipart/form-data; boundary="#{boundary}"}, 'Cookie' => @cookie}, :body    => body }
        response = Excon.send(method, @url, :path => path, :headers => url_request[:headers], :body => url_request[:body])
        status(response, 200, 'Failed to upload firmware file.')
        JSON.parse(response.body)   
      end

      #Delete perticular firmware file from server
      def delete_firmware_file(file)
        response = request(:delete, "/devmgr/v2/firmware/upload/#{file}")
        status(response, 204, 'Failed to delete firmware file')
      end

      #Get current firmware upgrade request detail
      def get_firmware_upgrade_details(sys_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/cfw-upgrade/")
        response
        #status(response, 200, 'Failed to get firmware upgrade details')
        # if response.status == 422
        #   fail("Error : #{response.body}")
        # end
        # JSON.parse(response.body)
      end

      #Check compatibility for upgrade firmware controller.
      def check_firmware_compatibility(request_body)
        response = request(:post, "/devmgr/v2/firmware/compatibility-check/",request_body.to_json)
        status(response, 200, 'Failed to check compatibility for upgrade firmware controller.')
        JSON.parse(response.body)
      end

      #Check compatibility for upgrade firmware controller.
      def get_firmware_compatibility_check_status(requestid)
        response = request(:get, "/devmgr/v2/firmware/compatibility-check/?requestId=#{requestid}")
        status(response, 200, 'Failed to get status of a firmware compatibility check operation.')
        JSON.parse(response.body)
      end

      #Upgrade firmware
      def upgrade_controller_firmware(sys_id,request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/cfw-upgrade/",request_body.to_json)
        status(response, 202, 'Failed to upgrade firmware controller')
        JSON.parse(response.body)
      end

      #Activate firmware
      def activate_controller_firmware(sys_id,request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/cfw-upgrade/activate",request_body.to_json)
        status(response, 200, 'Failed to activate firmware controller')
        JSON.parse(response.body)
      end

      #This API returns version information for the software that is currently running (same as /utils/about) 
      #and the version of any staged updates.  If there are no updates, the array of version data is empty.
      def get_web_proxy_update
        response = request(:get, "/devmgr/v2/upgrade")
        status(response, 200, 'Failed to web proxy upgrade detail')
        JSON.parse(response.body)
      end

      #Starts a download of software updates from the update server to the staging area.
      def download_web_proxy_update(force)
        req_url=''
        if force != nil
          req_url = "/devmgr/v2/upgrade/download?force=#{force}"
        else
          req_url = "/devmgr/v2/upgrade/download"
        end
        response = request(:post, req_url)
        status(response, 200, 'Failed to download web proxy updates')
        JSON.parse(response.body)
      end

      #Starts a reload of the software.  If any updates are downloaded, they will be loaded.
      def reload_web_proxy_update
        response = request(:post, "/devmgr/v2/upgrade/reload")
        status(response, 200, 'Failed to reload web proxy updates')
        JSON.parse(response.body)
      end

      #Get a set of events are posted to the event queue devmgr/v2/events that indicate the status of the process 
      def get_events
        response = request(:get, "/devmgr/v2/events")
        #status(response, 200, 'Failed to get current events from server')
        #JSON.parse(response.body)
        response
      end

      def get_flash_cache(sys_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache")
        status(response, 200, 'Failed to get flash cache')
        JSON.parse(response.body)        
      end

      def is_flash_cache_exist(sys_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache")
        if response.status == 200 
          JSON.parse(response.body)
        else
          false
        end 
      end

      def get_drives(sys_id)
        response = request(:get, "/devmgr/v2/storage-systems/#{sys_id}/drives")
        status(response, 200, 'Failed to get drives')
        JSON.parse(response.body)        
      end

      def suspend_flash_cache(sys_id)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache/suspend")
        status(response, 200, 'Failed to suspend flash cache')
      end

      def resume_flash_cache(sys_id)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache/resume")
        status(response, 200, 'Failed to resume flash cache')
      end

      def create_flash_cache(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache", request_body.to_json)
        status(response, 200, 'Failed to create flash cache')
      end

      def delete_flash_cache(sys_id)
        response = request(:delete, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache")
        status(response, 204, 'Failed to delete flash cache')
      end

      def update_flash_cache(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache/configure", request_body.to_json)
        status(response, 200, 'Failed to update flash cache')
      end

      def flash_cache_add_drives(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache/addDrives", request_body.to_json)
        status(response, 200, 'Failed to add drives to flash cache')
      end

      def flash_cache_remove_drives(sys_id, request_body)
        response = request(:post, "/devmgr/v2/storage-systems/#{sys_id}/flash-cache/removeDrives", request_body.to_json)
        status(response, 200, 'Failed to remove drives to flash cache')
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
	    #Puppet.debug("REAQUEST URL #{method} #{@url} #{path} #{@connect_timeout} #{body}")
        response = Excon.send(method, @url, :path => path, :headers => web_proxy_headers, :body => body, :connect_timeout => @connect_timeout)
      end

      # Set headers for web proxy.
      def web_proxy_headers
        { 'Accept' => 'application/json', 'Content-Type' => 'application/json', 'cookie' => @cookie }
      end
    end
  end
end
