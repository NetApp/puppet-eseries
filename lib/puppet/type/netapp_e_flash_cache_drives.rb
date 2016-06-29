require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_flash_cache_drives) do
  @doc = 'Manage Netapp E series flash cache drives'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a storagesystem.' unless @parameters.include?(:storagesystem)
    raise Puppet::Error, 'You must specify a flash cachename.' unless @parameters.include?(:cachename)
    raise Puppet::Error, 'You must specify a flash cache block name.' unless @parameters.include?(:name)
    raise Puppet::Error, 'You must specify a diskids.' unless @parameters.include?(:diskids)
  end

  newparam(:name, :namevar => true) do
    desc 'block name.'
  end

  newparam(:cachename) do
    desc 'Flash Cache Name.'
    validate do | value | 
      raise Puppet::Error, 'Value of cachename must not be empty.' if value.strip() == ''
      unless value =~ /^[a-zA-Z0-9_\-]{1,30}$/
        fail("#{value} is 'Invalid cachename - (A name can only consist of letters, numbers and the special characters of underscore(_) and dash sign(-)). Max 30 chars allowed.")
      end
    end
  end

  newparam(:storagesystem) do
    desc 'Storage system id.'
    validate do | value | 
      raise Puppet::Error, 'Value of storagesystem must not be empty.' if value.strip() == ''
    end
  end

  newparam(:diskids, :array_matching => :all) do
    desc 'Drives reference'
    validate do |value|
      if value.length == 0
        fail("Parameter diskids is empty")  
      else
        value.each do |data|
          fail("value of diskids must not be empty.") if data.strip() == ''
        end
      end
    end
  end

  newproperty(:ensure) do
    defaultto :present

    def retrieve
      provider.exists?
    end

    newvalue :present do
      provider.add
    end

    newvalue :absent do
      provider.remove
    end

  end

end  
