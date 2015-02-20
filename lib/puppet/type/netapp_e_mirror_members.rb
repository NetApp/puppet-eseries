require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_mirror_members) do
  @doc = 'Manage Netapp E series mirror members'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a primary volume name.' unless @parameters.include?(:primaryvolume)
    raise Puppet::Error, 'You must specify a secondary volume name.' unless @parameters.include?(:secondaryvolume)
    raise Puppet::Error, 'You must specify a name for mirror group.' unless @parameters.include?(:mirror)
  end

  newparam(:name, :namevar => true) do
  end

  newparam(:primaryvolume) do
    desc 'Name of primary volume.'
  end

  newparam(:secondaryvolume) do
    desc 'Name of secondary volume.'
  end

  newparam(:mirror) do
    desc 'Name of mirror group.'
  end

  newproperty(:ensure) do
    defaultto :present

    def retrieve
      provider.exist?
    end

    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end

  newparam(:capacity) do
    desc 'Percentage of the capacity of the primary volume to use for the repository capacity.'
  end

  newparam(:scanmedia, :boolean => true, :parent => Puppet::Parameter::Boolean) do
  end

  newparam(:validateparity, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Validate repository parity.'
  end

  # internal use
  newparam(:memberid) do
  end

  newparam(:storagesystem) do
  end

  newparam(:primaryvolid) do
  end

  newparam(:secondvolid) do
  end

  newparam(:primarypoolid) do
  end

  newparam(:secondpoolid) do
  end

  newparam(:mirrorid) do
  end
end
