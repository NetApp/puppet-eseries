require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_volume) do
  @doc = 'Manage Netapp E series volume'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a name of volume.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storage pool name.' unless @parameters.include?(:storagepool)
    raise Puppet::Error, 'You must specify a size unit.' unless @parameters.include?(:sizeunit)
    raise Puppet::Error, 'You must specify a size.' unless @parameters.include?(:size)
    if @original_parameters[:thin]
      raise Puppet::Error, 'You must specify a maximum repository size.' unless @parameters.include?(:maxrepositorysize)
      raise Puppet::Error, 'You must specify repository size.' unless @parameters.include?(:repositorysize)
    else
      raise Puppet::Error, 'You must specify segment size.' unless @parameters.include?(:segsize)
    end
  end

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

  newparam(:dataassurance, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'If true data assurance enabled'
  end

  newparam(:thin, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'If true thin volume will be created'
    defaultto false
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

  newparam(:defaultmapping, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Create the default volume mapping.'
  end

  newparam(:expansionpolicy) do
    desc 'Thin Volume expansion policy. If automatic, the thin volume will be expanded automatically when capacity is exceeded, if manual, the volume must be expanded manually.'
    newvalues('unknown', 'manual', 'automatic', '__UNDEFINED')
  end

  newparam(:cachereadahead, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'If true automatic cache read-ahead enabled'
  end
end
