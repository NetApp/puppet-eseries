require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_group_snapshot) do
  @doc = 'Manage Netapp E series Consistency Group Snapshots'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a block name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the block.'
    validate do | value | 
      raise Puppet::Error, 'Value of block name must not be empty.' if value.strip() == ''
    end
  end
 
  newparam(:consistencygroup) do
    desc 'The name of the consistency group.'
    validate do | value | 
      raise Puppet::Error, 'Value of consistency group name must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid consistency group - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:storagesystem) do
    desc 'Storage system id.'
    validate do | value | 
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
  end

  newproperty(:ensure) do
    defaultto :present

    def retrieve
      provider.exists?
    end

    newvalue :present do
      provider.create
    end
    
    newvalue :absent do
      provider.destroy
    end

  end

  #Internal Use
  newparam(:cg_id, :readonly => true) do
    desc 'Consistency group id.'
  end

end