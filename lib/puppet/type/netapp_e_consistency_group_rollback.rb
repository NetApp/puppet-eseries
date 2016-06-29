require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_group_rollback) do
  @doc = 'Manage Netapp E series consistency group rollback'

  apply_to_device

   validate do
    raise Puppet::Error, 'You must specify a block name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
    raise Puppet::Error, 'You must specify a snapshot sequence number.' unless @parameters.include?(:snapshotnumber)
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
  
  newproperty(:snapshotnumber) do
    desc 'Snapshot Sequence Number.'
    validate do | value | 
      raise Puppet::Error, 'Value of snapshot number must not be empty.' if value.to_s().strip() == ''
      unless value.to_s() =~ /^[0-9]{1,}$/
        fail("#{value} is 'Invalid Snapshot Sequence Number - Only digits are allowed.")
      end
    end
    def retrieve
    	provider.rollback
    end
  end

end

