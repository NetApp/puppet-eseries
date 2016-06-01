require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_consistency_group_rollback).provide(:netapp_e_consistency_group_rollback, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series consistency_group rollback'

 mk_resource_methods
 def rollback
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
      fail("Puppet::Provider::Netapp_e_consistency_group_rollback: Storage System #{@resource[:storagesystem]} does not exist.")
    else
      cg_id = transport.get_consistency_group_id(@resource[:storagesystem], @resource[:consistencygroup])
      if cg_id == false
      	  fail("Puppet::Provider::Netapp_e_consistency_group_rollback: Consistency group #{@resource[:consistencygroup]} does not exist.")
      else
        snapshots = transport.get_consistency_group_snapshots_by_seqno(@resource[:storagesystem], cg_id, @resource[:snapshotnumber])
        if snapshots.size  == 0
          fail("Puppet::Provider::Netapp_e_consistency_group_rollback: Specified Snapshot Number #{@resource[:snapshotnumber]} does not exist.")
        else
          transport.rollback_consistency_group(@resource[:storagesystem], cg_id, @resource[:snapshotnumber])
          Puppet.debug("Puppet::Provider::Netapp_e_consistency_group_rollback: Consistency group #{@resource[:consistencygroup]} rollback successfull. \n")  
          ''
        end   	      
      end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
 end

end
