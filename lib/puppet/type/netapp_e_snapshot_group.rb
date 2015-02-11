require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_snapshot_group) do
  @doc = 'Manage Netapp E series snapshot groups'

  apply_to_device
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the new snapshot group.'
  end

  newproperty(:id, :readonly => true) do
    desc 'Snapshot group ID.'
  end

  newparam(:storagesystem) do
    desc 'Storage system ID'
  end

  newparam(:storagepool) do
    desc 'The name of the storage pool to allocate the repository volume'
  end

  newparam(:volume) do
    desc 'Then name of the volume for the new snapshot group'
  end

  newproperty(:poolid, :readonly => true) do
    desc 'The identifier of the storage pool to allocate the repository volume'
  end

  newparam(:repositorysize) do
    desc 'The percent size of the repository in relation to the size of the base volume.'
  end

  newproperty(:warnthreshold) do
    desc 'The repository utilization warning threshold, as a percentage of the repository volume capacity.'
  end

  newproperty(:limit) do
    desc 'The automatic deletion indicator. If non-zero, the oldest snapshot image\
          will be automatically deleted when creating a new snapshot image to keep\
          the total number of snapshot images limited to the number specified.'
  end

  newproperty(:policy) do
    desc 'The behavior on when the data repository becomes full.'
    newvalues('unknown', 'failbasewrites', 'purgepit', '__UNDEFINED')
  end
end
