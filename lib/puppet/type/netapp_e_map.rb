require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_map) do
  @doc = 'Manage Netapp E series volume mappings'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a name for volume mapping.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a storage system name.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a source of mapping.' unless @parameters.include?(:source)
    raise Puppet::Error, 'You must specify a target of mapping.' unless @parameters.include?(:target)
    raise Puppet::Error, 'You must specify a lun number.' unless @parameters.include?(:lun)
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

  newparam(:source) do
    desc 'The mappable object such as a volume or snapshot volume.'
  end

  newparam(:target) do
    desc 'The host group or a host for the volume mapping.'
  end

  newparam(:type) do
    desc 'Type of target'
    newvalues(:host, :hostgroup)
  end

  newparam(:lun) do
    desc 'The LUN for the volume mapping.'
  end

  newproperty(:ensure) do
    desc 'Check if lun mappings is set'

    def retrieve
      provider.transport.get_lun_mapping(@resource[:storagesystem], @resource[:lun])
    rescue => detail
      raise Puppet::Error, "Error: #{detail}"
    end

    newvalue :present do
      provider.create(@resource[:storagesystem], @resource[:source], @resource[:target], @resource[:type], @resource[:lun])
    end

    newvalue :absent do
      provider.destroy(@resource[:storagesystem], @resource[:lun])
    end
  end
end
