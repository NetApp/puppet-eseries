require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_consistency_group_snapshot_view).provide(:netapp_e_consistency_group_snapshot_view, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series snapshot consistency groups'

  mk_resource_methods

  def exists?
   if @resource[:ensure] == :present
      false
   else
      true
   end
  end

  def create
    request_body = {
     :name =>  @resource[:viewname],
     :validateParity => @resource[:validateparity],
    }
    if @resource[:viewtype].to_s == "bySnapshot"
      request_body[:pitSequenceNumber]  = @resource[:snapshotnumber]
    end
    #Get Repository Pool Id if 'repositorypool' provided
    if @resource[:repositorypool] != nil
      storagepool = transport.get_storage_pools
      storagepool.each do |sp|
        if sp['label'] == @resource[:repositorypool]
          @resource[:repositorypoolid] = sp['id']
          break
        end
      end  
      request_body[:repositoryPoolId] = @resource[:repositorypoolid]
    end
    request_body[:accessMode] = @resource[:accessmode] if @resource[:accessmode]
    if @resource[:scanmedia] != nil
      request_body[:scanMedia] = @resource[:scanmedia] 
    end
    
    if @resource[:repositorypercent]
      if @resource[:repositorypercent] < 0 or @resource[:repositorypercent] > 100
        fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: Repository percent should between 0 and 100.") 
      else
        request_body[:repositoryPercent] = @resource[:repositorypercent]
      end
    end

    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
      fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: Storage System #{@resource[:storagesystem]} does not exist.")
    else
      cg_id = transport.get_consistency_group_id(@resource[:storagesystem], @resource[:consistencygroup])
      if cg_id == false
         fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified consistency group #{@resource[:consistencygroup]} does not exist.")
      end
      snapshots = transport.get_consistency_group_snapshots_by_seqno(@resource[:storagesystem], cg_id, @resource[:snapshotnumber])
      if snapshots.size  == 0
        fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified Snapshot Number #{@resource[:snapshotnumber]} does not exist.")
      end   
      if @resource[:viewtype].to_s == 'byVolume'
          if not @resource[:volume]
            fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : You must specify a volume.")
          else
            vol_id = transport.get_volume_id(@resource[:storagesystem], @resource[:volume])
            if vol_id == false
              fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified Volume #{@resource[:volume]} does not exist in storage system.")
            else
              pit_id = transport.get_pit_id_by_volume_id(@resource[:storagesystem], cg_id, @resource[:snapshotnumber], vol_id)
              if pit_id == false
                  fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified Volume #{@resource[:volume]} does not exist in consistency group snapshot.")
              else
                  request_body[:pitId] = pit_id 
              end
            end
          end
      end
      Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: Checking existence of consistency group snapshot view #{@resource[:viewname]}. \n")
      
      view_id = transport.get_consistency_group_snapshot_view_id(@resource[:storagesystem], cg_id, @resource[:viewname])
      if view_id == false
          transport.create_consistency_group_snapshot_view(@resource[:storagesystem],cg_id, request_body)
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: #{@resource[:viewname]} view created successfully. \n")
      else
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: Specified View #{@resource[:viewname]} already exists.")
      end
    end
    
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end
  
  def destroy
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
      fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view: Storage System #{@resource[:storagesystem]} does not exist.")
    else
      cg_id = transport.get_consistency_group_id(@resource[:storagesystem], @resource[:consistencygroup])
      if cg_id == false
          fail("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified consistency group #{@resource[:consistencygroup]} does not exist.")
      end
      view_id = transport.get_consistency_group_snapshot_view_id(@resource[:storagesystem], cg_id, @resource[:viewname])
      if view_id == false
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : Specified View #{@resource[:viewname]} does not exist.")
      else
          transport.delete_consistency_group_snapshot_view(@resource[:storagesystem], cg_id, view_id)
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot_view : #{@resource[:viewname]} view deleted successfully. \n")
      end
    end  
  end
   
end
