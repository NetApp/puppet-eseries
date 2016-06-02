require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_snapshot_image) do
  @doc = 'Manage Netapp E series snapshot images'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a snapshot group.' unless @parameters.include?(:group)
    #raise Puppet::Error, 'You must specify a schedule how often do a snapshot.' unless @parameters.include?(:schedule)
  end

  newparam(:name, :namevar => true) do
  end

  newparam(:storagesystem) do
    desc 'Storage system ID.'
  end

  newparam(:group) do
    desc 'Name of snapshot group.'
  end

  newproperty(:ensure) do
    defaultto :present
    desc 'Check if snapshot image exists'

    def retrieve
      :absent
    end

    newvalue :present do
      provider.create
    end
  end
end
