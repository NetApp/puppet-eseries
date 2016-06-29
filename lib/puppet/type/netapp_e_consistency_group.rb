require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_group) do
  @doc = 'Manage Netapp E series consistency group'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
  end

  newparam(:name, :namevar => true) do
    desc 'The user define label for manifest block'
  end

  newparam(:consistencygroup) do
    desc 'The user-label to assign to the new consistency group'
    validate do | value | 
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid consistency group - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newproperty(:storagesystem, :readonly => true) do
    desc 'Consistency group storage system id'
    validate do | value |
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
  end

  newproperty(:id, :readonly => true) do
    desc 'Consistency group id.'
  end

  newproperty(:fullwarnthresholdpercent) do
    desc 'The full warning threshold percent'
    validate do | value | 
      raise Puppet::Error, 'Value of fullwarnthresholdpercent must not be empty.' if value == ''
      raise Puppet::Error, 'Warning threshold percent should between 0 and 100.' if value < 0 or value > 100
    end
  end

  newproperty(:autodeletethreshold) do
    desc 'The auto-delete threshold. Automatically delete oldest snapshots after this many'
    validate do | value | 
      raise Puppet::Error, 'Value of autodeletethreshold must not be empty.' if value == ''
      raise Puppet::Error, 'Auto delete threshold percent should between 0 and 32.' if value < 0 or value > 32
    end
  end

  newproperty(:repositoryfullpolicy) do
    desc 'The repository full policy.'
    newvalues('purgepit', 'failbasewrites')
  end

  newproperty(:rollbackpriority) do
    desc 'Roll-back priority'
    newvalues('highest', 'high', 'medium', 'low', 'lowest')
  end

  newproperty(:ensure) do
    defaultto :present

    def retrieve
      provider.exist?
    rescue => detail
      raise Puppet::Error, "Error Message: #{detail}"
    end

    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end
end
