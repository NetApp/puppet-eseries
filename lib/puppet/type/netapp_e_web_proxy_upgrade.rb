require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_web_proxy_upgrade) do
  @doc = 'Manage Netapp E SANtiricity Web Proxy Server Upgrade'

  apply_to_device

  validate do
     raise Puppet::Error, 'You must specify a name of resource block.' unless @parameters.include?(:name)
  end

  newparam(:name, :namevar => true) do
    desc 'Name of resource block.'
    validate do | value | 
      raise Puppet::Error, 'Value of resource block name must not be empty.' if value.strip() == ''
    end
  end

  newproperty(:ensure) do
    defaultto :upgraded
    
    newvalue :upgraded do
      provider.upgrade(false)
    end

    newvalue :staged do
      provider.upgrade(true)
    end

    newvalue :activated do
      provider.activate
    end
    
  end

  newparam(:force) do
    
  end

  #Internal Use

  newparam(:correlationid) do
    desc 'Correlationid of upgrade download/reload requests.'
  end

end