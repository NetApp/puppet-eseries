require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_consistency_group_snapshot_view) do
  @doc = 'Manage Netapp E series consistency group snapshot views'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a block name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a view name.' unless @parameters.include?(:viewname)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a consistency group name.' unless @parameters.include?(:consistencygroup)
  end

  newparam(:name, :namevar => true) do
    desc 'The name of the block.'
    validate do | value | 
      raise Puppet::Error, 'Value of block name must not be empty.' if value.strip() == ''
    end
  end

  newparam(:viewname) do
    desc 'View Name.'
    validate do | value | 
      raise Puppet::Error, 'Value of view name must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid View Name - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:consistencygroup) do
    desc 'The name of the consistency group.'
    validate do | value | 
      raise Puppet::Error, 'Value of consistency group name must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid consistency group - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:storagesystem) do
    desc 'Storage system id.'
    validate do | value | 
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
  end

  newparam(:snapshotnumber) do
    desc 'Snapshot Sequence Number.'
    validate do | value | 
      raise Puppet::Error, 'Value of snapshot number must not be empty.' if value.to_s().strip() == ''
    end
  end

  newparam(:viewtype) do
    desc 'View Type.'
    defaultto 'bySnapshot'
    newvalues('byVolume', 'bySnapshot')
  end
  
  newparam(:validateparity, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'validate parity.'
    validate do | value | 
      raise Puppet::Error, 'Value of validate parity must not be empty.' if value.to_s().strip() == ''
    end
  end

  newparam(:repositorypool) do
    desc 'Storage Pool.'
    validate do | value | 
      raise Puppet::Error, 'Value of repository pool must not be empty.' if value.to_s().strip() == ''
    end
  end

  newparam(:accessmode) do
    desc 'Access Mode of volume.'
    defaultto 'readWrite'
    newvalues('readWrite', 'readOnly')
  end

  newparam(:repositorypercent) do
    desc 'Repository percent.'
    validate do | value | 
      raise Puppet::Error, 'Value of repositorypercent must not be empty.' if value == ''
      raise Puppet::Error, 'Repository percent should between 0 and 100.' if value < 0 or value > 100
    end
  end
  
  newparam(:volume) do
    desc 'Volume Name.'
    validate do | value | 
      if @resource[:viewtype].to_s() == 'byVolume'
        raise Puppet::Error, 'Value of volume must not be empty.' if value.to_s().strip() == ''
        unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
          fail("#{value} is 'Invalid Volume Name - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
        end
      end
    end
  end

  newparam(:scanmedia, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'Scan Media.'
  end
  
  newproperty(:ensure) do
    defaultto :present

    def retrieve
      provider.exists?
    end

    newvalue :present do
      fail("You must specify a view type.") if not @resource[:viewtype]
      fail("You must specify a snapshot number.") if not @resource[:snapshotnumber]
      @resource[:validateparity] = false if @resource[:validateparity] == nil
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end

  #Internal Use
  newparam(:pitid) do
    desc 'The Id of the PIT.'
  end

  newparam(:repositorypoolid) do
    desc 'Reference Id to the Storage Pool.'
  end

end



