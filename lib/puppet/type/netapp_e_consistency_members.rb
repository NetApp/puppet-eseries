require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_members) do
  @doc = 'Manage Netapp E series consistency group members'

  apply_to_device

  validate do
     raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
     raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
     raise Puppet::Error, 'You must specify a volume name.' unless @parameters.include?(:volume)
  end

  newparam(:name, :namevar => true) do
    desc 'The name of netapp_e consistency group members block'
  end

  newparam(:volume) do
    desc 'Name of volume.'
    validate do | value | 
      raise Puppet::Error, 'Value of volume name must not be empty.' if value.strip() == ''
    end
  end
  
  newparam(:consistencygroup) do
    desc 'Name of consistency group.'
    validate do | value | 
      raise Puppet::Error, 'Value of consistency group name must not be empty.' if value.strip() == ''
    end
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

  newparam(:repositorypool) do
    desc 'The repository volume pool.'
    validate do | value | 
      raise Puppet::Error, 'Value of repository volume pool must not be empty.' if value.strip() == ''
    end
  end

  newparam(:scanmedia,:boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Scan media enable/disable.'
  end

  newparam(:validateparity, :boolean => true, :parent => Puppet::Parameter::Boolean)do
    desc 'Validate repository parity enable/disable.'
  end

  newparam(:repositorypercent) do
    desc 'Repository percent.'
    validate do | value | 
      raise Puppet::Error, 'Value of repositorypercent must not be empty.' if value == ''
      raise Puppet::Error, 'Repository percent should between 0 and 100.' if value < 0 or value > 100
    end
  end

  newparam(:retainrepositories, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'Delete all repositories assosiated with the member volume or not.'
  end
  
  newparam(:storagesystem) do
    validate do | value |
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
  end

  # internal use
  newparam(:volumeid) do
  end
  
  newparam(:consistencyid) do
  end
  
  newparam(:repositorypoolid) do
  end
end
