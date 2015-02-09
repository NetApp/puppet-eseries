require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_host_group) do
  @doc = 'Manage Netapp E series host groups'

  apply_to_device
  ensurable

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
