require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_volume) do
  @doc = 'Manage Netapp E series volume'

  apply_to_device
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The user-label to assign to the new volume.'
  end

  newproperty(:id, :readonly => true) do
    desc 'Volume id.'
  end

  newparam(:storagesystem) do
    desc 'Storage system ID'
  end

  newparam(:storagepool) do
    desc 'Name of storage poll from which the volume will be allocated'
  end

  newproperty(:poolid, :readonly => true) do
    desc 'The identifier of the storage pool from which the volume will be allocated.'
  end

  newparam(:sizeunit) do
    desc 'Unit for size'
    newvalues('bytes', 'b', 'kb', 'mb', 'gb', 'tb', 'pb', 'eb', 'zb', 'yb')
  end

  newparam(:size) do
    desc 'Number of units to make the volume'
  end

  newparam(:segsize) do
    desc 'The segment size of the volume'
  end

  newparam(:dataassurance) do
    desc 'If true data assurance enabled'
    defaultto :false
    newvalues(:true, :false)
  end

  newparam(:thin) do
    desc 'If true thin volume will be created'
    defaultto :false
    newvalues(:true, :false)
  end

  newparam(:repositorysize) do
    desc 'Number of units to make the repository volume, which is the backing for the thin volume.'
  end

  newparam(:maxrepositorysize) do
    desc 'Maximum size to which the thin volume repository can grow. Must be between 4GB & 256GB'
  end

  newparam(:owningcontrollerid) do
    desc 'Set the initial owning controller. (optional)'
  end

  newparam(:growthalertthreshold) do
    desc 'The repository utilization warning threshold (in percent).'
  end

  newparam(:defaultmapping) do
    desc 'Create the default volume mapping.'
    defaultto :false
    newvalues(:true, :false)
  end

  newparam(:expansionpolicy) do
    desc 'Thin Volume expansion policy. If automatic, the thin volume will be expanded automatically when capacity is exceeded, if manual, the volume must be expanded manually.'
    defaultto 'automatic'
    newvalues('unknown', 'manual', 'automatic', '__UNDEFINED')
  end

  newparam(:cachereadahead) do
    desc 'If true automatic cache read-ahead enabled'
    defaultto :false
    newvalues(:true, :false)
  end
end
