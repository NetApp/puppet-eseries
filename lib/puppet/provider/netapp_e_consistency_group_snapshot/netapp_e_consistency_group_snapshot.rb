require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_consistency_group_snapshot).provide(:netapp_e_consistency_group_snapshot, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series snapshot consistency groups'

  mk_resource_methods

  def exists?
   if @resource[:ensure] == :present
      :absent
   else
      :present
   end
  end

  def create
    request_body = {}
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
      fail("Puppet::Provider::Netapp_e_consistency_group_snapshot: Storage System #{@resource[:storagesystem]} does not exist.")
    else
      cg_id = transport.get_consistency_group_id(@resource[:storagesystem], @resource[:consistencygroup])
      if cg_id == false
        fail("Puppet::Provider::Netapp_e_consistency_group_snapshot: Consistency group #{@resource[:consistencygroup]} does not exist.")
      else
        created_snapshotno = 0
        data = transport.create_consistency_group_snapshot(@resource[:storagesystem],cg_id, request_body)
        data.each do | val | 
          created_snapshotno = val["pitSequenceNumber"]
        end
        Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot: Consistency group #{@resource[:consistencygroup]} snapshot with snapshot number(#{created_snapshotno}) created successfully. \n")
      end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end
  
  def destroy
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
      fail("Puppet::Provider::Netapp_e_consistency_group_snapshot: Storage System #{@resource[:storagesystem]} does not exist.")
    else
      cg_id = transport.get_consistency_group_id(@resource[:storagesystem], @resource[:consistencygroup])
      if cg_id == false
        fail("Puppet::Provider::Netapp_e_consistency_group_snapshot: Consistency group #{@resource[:consistencygroup]} does not exist.")
      else
        oldest_seq_no = transport.get_oldest_sequence_no(@resource[:storagesystem], @resource[:consistencygroup])
        if oldest_seq_no > 0
          transport.remove_oldest_consistency_group_snapshot(@resource[:storagesystem], cg_id, oldest_seq_no)
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot: Consistency group #{@resource[:consistencygroup]} oldest snapshot with snapshot number(#{oldest_seq_no}) removed successfully. \n")
        else
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_snapshot: No snapshots exist for Consistency group #{@resource[:consistencygroup]}.")
        end
      end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

end
