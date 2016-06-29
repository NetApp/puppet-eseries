require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_consistency_multiple_members).provide(:netapp_e_consistency_multiple_members, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series consistency group members'
  
  mk_resource_methods 
  
  def addvolumes

    #Get Consistency group id from all consistency group API
    consistency_groups = transport.get_consistency_groups
    
    consistency_groups.each do |cg|
      if cg['label'] == @resource[:consistencygroup] 
        if cg['storagesystem'] == @resource[:storagesystem] 
            @resource[:consistencyid] = cg['cgRef']
            break
        end
      end
    end

    fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Consistency group #{@resource[:consistencygroup]} does not exist.") unless @resource[:consistencyid] 

    #Get Volume ID from get all volume API
    volumes = transport.get_volumes
    storagepool = transport.get_storage_pools

    @resource[:volumes].each do |curvol|
      
      if curvol['scanmedia']
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Scan media value shuold be true/false for volume '#{curvol['volume']}'.") if curvol['scanmedia']!=true and curvol['scanmedia']!=false
      end

      if curvol['validateparity']
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Validate repository parity shuold be true/false for volume '#{curvol['volume']}'.") if curvol['validateparity']!=true and curvol['validateparity']!=false
      end

      if curvol['repositorypercent']
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Value of repositorypercent should not blank for volume '#{curvol['volume']}'.") if curvol['repositorypercent'] == ''
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Repository percent should between 0 and 100 for volume '#{curvol['volume']}'.") if curvol['repositorypercent'] < 0 or curvol['repositorypercent'] > 100
      end

      if curvol['volume']
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Value of volume should not blank.") if curvol['volume'] == ''
      end

      if curvol['repositorypool']
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Value of repositorypool should not blank.") if curvol['repositorypool'] == ''
      end

      flag = false  
      volumes.each do |vol|
        if vol['label'] == curvol['volume']
          curvol['volumeid'] = vol['id']
          flag = true
          break
        end
      end
    
      #If any one of the volume not found, will break execution.
      if !flag
        fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Volume '#{curvol['volume']}' information not found.")
      end
      
      #Get Repository Pool Id if 'repositorypool' provided
      sp_flag=false
      if curvol['repositorypool']
        storagepool.each do |sp|
          if sp['label'] == curvol['repositorypool']  and sp['storagesystem'] == @resource[:storagesystem]
            curvol['repositorypoolid'] = sp['id']
            sp_flag=true
            break
          end
        end

        #If any one of the stroage pool not found, will break execution.
        if !sp_flag
          fail("Puppet::Provider::Netapp_e_consistency_multiple_members: Stroage Pool #{curvol['repositorypool']} not found.")
        end
      end
    
    end #End of for each @resource[:volumes]


    #Get Consistency group member volumes to check is volume is already added in consistency group or not.
    members = transport.get_consistency_group_members(@resource[:storagesystem], @resource[:consistencyid])

    found_vol = Array.new
    not_found_vol = Array.new

    @resource[:volumes].each do |curvol|
      
      flag = false
      members.each do |mem|
          if mem['baseVolumeName'] == curvol['volume']
            found_vol.push curvol['volume']
            flag = true
            break
          end
      end

      if !flag
        not_found_vol.push curvol['volume']
        request_body = {
          :volumeId => curvol['volumeid'],
        }

        request_body[:repositoryPoolId] = curvol['repositorypoolid'] if curvol['repositorypoolid']
        request_body[:scanMedia] =curvol['scanmedia'] if curvol['scanmedia']
        request_body[:validateParity] = curvol['validateparity'] if curvol['validateparity']
        request_body[:repositoryPercent ] = curvol['repositorypercent'] if curvol['repositorypercent']

        transport.add_consistency_group_member(@resource[:storagesystem], @resource[:consistencyid], request_body)
      end
    end

    Puppet.debug("Puppet::Provider::Netapp_e_consistency_multiple_members: Consistency group member volume(s) #{not_found_vol.join(", ")} added successfully.") if not_found_vol.length > 0

    Puppet.debug("Puppet::Provider::Netapp_e_consistency_multiple_members: Consistency group member volume(s) #{found_vol.join(", ")} was/were already added.") if found_vol.length > 0
  end

end