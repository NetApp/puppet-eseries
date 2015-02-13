require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_snapshot_group) do
  @doc = 'Manage Netapp E series snapshot groups'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a volume.' unless @parameters.include?(:volume)
    raise Puppet::Error, 'You must specify a name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a warning threshold.' unless @parameters.include?(:warnthreshold)
    raise Puppet::Error, 'You must specify a limit' unless @parameters.include?(:limit)
    raise Puppet::Error, 'You must specify a policy' unless @parameters.include?(:policy)
    raise Puppet::Error, 'You must specify a storage pool' unless @parameters.include?(:storagepool)
  end

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
