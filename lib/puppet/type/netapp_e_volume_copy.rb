require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_volume_copy) do
  @doc = 'Manage Netapp E series snapshot volume'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a source volume.' unless @parameters.include?(:source)
    raise Puppet::Error, 'You must specify a target volume.' unless @parameters.include?(:target)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
  end

  newparam(:name, :namevar => true) do
    desc 'The user-label to assign to the new volume copy.'
  end

  newparam(:source) do
    desc 'Name of the source volume for the copy job.'
  end

  newparam(:sourceid, :readonly => true) do
    desc 'Id of the source volume for the copy job.'
  end

  newparam(:target) do
    desc 'Name of the target volume for the copy job. '
  end

  newparam(:targetid, :readonly => true) do
    desc 'Id of the target volume for the copy job. '
  end

  newparam(:storagesystem) do
    desc 'Storage system ID'
  end

  newparam(:vcid, :readonly => true) do
    desc 'Id of volume copy'
  end

  newproperty(:ensure) do
    defaultto :present

    def retrieve
      m_ids = provider.members_ids
      @resource[:sourceid] = m_ids[:source]
      @resource[:targetid] = m_ids[:target]
      @resource[:vcid] = provider.transport.volume_copy_id(
        @resource[:storagesystem],
        @resource[:sourceid], 
        @resource[:targetid]
      )
      @resource[:vcid] ? :present : :absent
    rescue => detail
      raise Puppet::Error, "#{detail}"
    end
    
    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end

  newparam(:copypriority) do
    desc 'The priority of the copy job (0 is the lowest priority, 4 is the highest priority)'
    defaultto 'priority2'
    newvalues('priority0', 'priority1', 'priority2', 'priority3', 'priority4', '__UNDEFINED') 
  end

  newparam(:targetwriteprotected, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Specifies whether to block write I/O to the target volume while the copy job exists.'
  end

  newparam(:disablesnapshot, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Will disable the target snapshot after the copy completes and purge\
          the associated group when the copy pair is deleted.'
  end
end

