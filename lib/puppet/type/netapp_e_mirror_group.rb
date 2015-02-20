require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_mirror_group) do
  @doc = 'Manage Netapp E series mirror group'

  apply_to_device
  ensurable

  validate do
    raise Puppet::Error, 'You must specify a primary storage system id.' unless @parameters.include?(:primaryarray)
    raise Puppet::Error, 'You must specify a secondary storage system id.' unless @parameters.include?(:secondaryarray)
    raise Puppet::Error, 'You must specify a name for mirror group.' unless @parameters.include?(:name)
    if @parameters.include?(:syncinterval)
      raise Puppet::Error, 'You must specify a sync warning threshold.' unless @parameters.include?(:syncthreshold)
      raise Puppet::Error, 'You must specify a recovery point warning threshold.' unless @parameters.include?(:recoverythreshold)
      raise Puppet::Error, 'You must specify a repository utilization warning threshold.' unless @parameters.include?(:repothreshold)
    end
  end

  newparam(:name, :namevar => true) do
    desc 'The user-label to assign to the new async mirror group.'
  end

  newparam(:primaryarray) do
    desc 'The id of the secondary array.'
  end

  newparam(:secondaryarray) do
    desc 'The id of the secondary array.'
  end

  newproperty(:storagesystem, :readonly => true) do
  end

  newparam(:interfacetype) do
    desc 'The intended protocol to use if both Fibre and iSCSI are available.'
    newvalues('fibre', 'iscsi', 'fibreAndIscsi', 'none')
  end

  newproperty(:syncinterval) do
    desc 'Sync interval (minutes).'
  end

  newproperty(:recoverythreshold) do
    desc 'Recovery point warning threshold (minutes).'
  end

  newproperty(:repothreshold) do
    desc 'Repository utilization warning threshold.'
  end

  newproperty(:syncthreshold) do
    desc 'Sync warning threshold (minutes).'
  end
end
