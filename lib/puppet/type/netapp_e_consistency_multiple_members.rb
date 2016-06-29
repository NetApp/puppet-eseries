require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_multiple_members) do
  @doc = 'Manage Netapp E series consistency group members'

  apply_to_device

  validate do
     raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
     raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
     raise Puppet::Error, 'You must specify a list of volumes.' unless @parameters.include?(:volumes)
  end

  newparam(:name, :namevar => true) do
    desc 'Name of volume.'
  end
  
  newparam(:consistencygroup) do
    desc 'Name of consistency group.'
    validate do | value | 
      raise Puppet::Error, 'Value of consistency group name must not be empty.' if value.strip() == ''
    end
  end

  newproperty(:volumes, :array_matching => :all) do
    desc 'Volume details'
    
    validate do |value|
      fail("Parameter volumes is empty") if value.length == 0
      fail("Parameter 'volume' not found in volumes parameter") unless value['volume']
    end
  end

  newproperty(:storagesystem) do

    validate do | value | 
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
    
    defaultto :present

    def retrieve    
        provider.addvolumes
    rescue => detail
      raise Puppet::Error, "Error Message: #{detail}"
    end
  end
  
  newparam(:consistencyid) do
  end

end
