require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_snapshot_volume) do
  @doc = 'Manage Netapp E series snapshot volume'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a snapshot image id' unless @parameters.include?(:imageid)
    raise Puppet::Error, 'You must specify a name of snapshot volume' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a view mode of snapshot volume' unless @parameters.include?(:viewmode)
    raise Puppet::Error, 'You must specify a storage pool for snapshot volume' unless @parameters.include?(:storagepool)
  end

  newparam(:name, :namevar => true) do
    desc 'The user-label to assign to the new snapshot volume.'
  end

  newparam(:imageid) do
    desc 'The identifier of the snapshot image used to create the new snapshot volume.'
  end

  newproperty(:id, :readonly => true) do
    desc 'Snapshot volume id.'
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

  newproperty(:fullthreshold) do
    desc 'The repository utilization warning threshold percentage.'
  end

  newparam(:viewmode) do
    desc 'The snapshot volume access mode.'
    newvalues('modeUnknown', 'readWrite', 'readOnly', '__UNDEFINED')
  end

  newparam(:repositorysize) do
    desc 'The size of the view in relation to the size of the base volume.'
  end
end
