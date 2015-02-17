require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_host_group) do
  @doc = 'Manage Netapp E series host groups'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a name of host groups.' unless @parameters.include?(:name)
  end

  newparam(:name, :namevar => true) do
    desc 'The user-label to assign to the new host group'
  end

  newparam(:storagesystem) do
    desc 'Storage system ID'
  end

  newparam(:hosts, :array_matching => true) do
    desc 'IDs of hosts'
  end
end
