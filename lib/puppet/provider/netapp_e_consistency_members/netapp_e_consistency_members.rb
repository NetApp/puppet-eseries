require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_consistency_members).provide(:netapp_e_consistency_members, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series consistency group members'
  
  mk_resource_methods 
  
  def exist?
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Checking existence of volume #{@resource[:volume]} in consistency group #{@resource[:consistencygroup]}. \n")
    
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
    fail("Puppet::Provider::Netapp_e_consistency_members: Consistency group #{@resource[:consistencygroup]} does not exist.") unless @resource[:consistencyid] 

    #Get Volume ID from get all volume API
    volumes = transport.get_volumes
    volumes.each do |vol|
      if vol['label'] == @resource[:volume]
        @resource[:volumeid] = vol['id']
      end
    end

    Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Volume #{@resource[:volume]} does not exist in storage system.") unless @resource[:volumeid] 
    return :absent unless @resource[:volumeid] 

    #Get Consistency group member volumes
    members = transport.get_consistency_group_members(@resource[:storagesystem], @resource[:consistencyid])
    members.each do |m|
      if m['baseVolumeName'] == @resource[:volume]
        Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Volume #{@resource[:volume]} is present in consistency group #{@resource[:consistencygroup]}.")
        return :present 
      end
    end
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Volume #{@resource[:volume]} is not present in consistency group #{@resource[:consistencygroup]}.")
    return :absent
  
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def create

    fail("Puppet::Provider::Netapp_e_consistency_members: Unable to add volume #{@resource[:volume]} in consistency group #{@resource[:consistencygroup]}.") unless @resource[:volumeid] 

    request_body = {
      :volumeId => @resource[:volumeid],
    }

    #Get Repository Pool Id if 'repositorypool' provided
    flag=false
    if @resource[:repositorypool]
      storagepool = transport.get_storage_pools
      storagepool.each do |sp|
        if sp['label'] == @resource[:repositorypool] and sp['storagesystem'] == @resource[:storagesystem]
          request_body[:repositoryPoolId] = sp['id']
          flag=true
          break
        end
      end  
      if !flag
        fail("Puppet::Provider::Netapp_e_consistency_members: Storage Pool #{@resource[:repositorypool]} not found.")
      end
    end

    request_body[:scanMedia] = @resource[:scanmedia] if @resource[:scanmedia]
    request_body[:validateParity] = @resource[:validateparity] if @resource[:validateparity]
    request_body[:repositoryPercent ] = @resource[:repositorypercent] if @resource[:repositorypercent]
    transport.add_consistency_group_member(@resource[:storagesystem], @resource[:consistencyid], request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Volume #{@resource[:volume]} added successfully in consistency group #{@resource[:consistencygroup]}.")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy

    @resource[:retainrepositories] = false unless @resource[:retainrepositories]

    transport.remove_consistency_group_member(@resource[:storagesystem], @resource[:consistencyid], @resource[:volumeid], @resource[:retainrepositories])
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_members: Volume #{@resource[:volume]} removed successfully from consistency group #{@resource[:consistencygroup]}.")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

end