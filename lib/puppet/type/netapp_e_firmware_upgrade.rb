require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_firmware_upgrade) do
  @doc = 'Manage Netapp E Storage Array Controller and NVSRAM firmware'

  apply_to_device

  validate do
     raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
     raise Puppet::Error, 'You must specify a firmware type to upgarde.' unless @parameters.include?(:firmwaretype)
  end

  newparam(:name, :namevar => true) do
    desc 'Name of Firmware upgrade manifest block.'
  end

  newparam(:filename) do
    desc 'Name of NVSRAM or Controller Firmware file name.'
    validate do | value | 
      raise Puppet::Error, 'Value of firmware file name must not be empty.' if value.strip() == ''
    end
  end
  
  newparam(:firmwaretype) do
    desc 'cfwfile will upgrade Controller firmware. nvsramfile will upgrade NVSRAM firmware.'
    newvalues('cfwfile', 'nvsramfile')
    validate do |value|
      if value.to_s == 'nvsramfile'
        raise Puppet::Error, 'This storage device does not support staged and activated operation for nvsramfile file.' if @resource['ensure'].to_s == 'staged' or @resource['ensure'].to_s == 'activated'
      else
        raise Puppet::Error, "Invalid value '#{value}'. Valid values are cfwfile, nvsramfile." if value != 'cfwfile'
      end
    end
  end

  newproperty(:ensure) do
    desc 'upgrade will ensure to upgrade controller firmware or NVSRAM or both if both are specified. stage will ensure to only install the controller firmware or NVSRAM or both if both are specified. But it will not activate the firmware versions. activate will ensure to upgrade the controller firmware to already installed the controller firmware or NVSRAM or both.'
    defaultto :upgraded

    def retrieve
      provider.exist?
    rescue => detail
      raise Puppet::Error, "Error Message: #{detail}"
    end

    newvalue :upgraded do
      raise Puppet::Error, 'You must specify a name of NVSRAM or Controller Firmware file name.' if @resource['filename'] == nil or @resource['filename'].to_s == '' 
      provider.upgrade(false)
    end

    newvalue :staged do
      raise Puppet::Error, 'You must specify a name of NVSRAM or Controller Firmware file name.' if @resource['filename'] == nil or @resource['filename'].to_s == '' 
      provider.upgrade(true)
    end

    newvalue :activated do
      provider.activate
    end
  end

  newparam(:storagesystem) do
    desc 'Storage System id which needs to be upgraded.'
    validate do | value | 
      raise Puppet::Error, 'Value of storage system must not be empty.' if value.strip() == ''
    end
  end
  
  newparam(:melcheck, :boolean => false, :parent => Puppet::Parameter::Boolean) do
    desc 'If it is true and any issues found in mel check, firmware would not be upgraded. If it is false, the issues will be ignored and firmware will be upgraded.'
  end

  newparam(:compatibilitycheck, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'True will check the compatibility of uploaded firmware version with the storage array. False will not perform the check. Firmware will not be upgraded if check is enabled and compatibility fails.'
  end

  newparam(:releasedbuildonly,:boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Only consider released firmware builds as valid Controller Firmware files for checking the compatibility.'
  end

  newparam(:waitforcompletion,:boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'true will wait for upgrade process to complete successfully. false will request to start the upgrade process and would not monitor success.'
  end

  #Internal Use


  newparam(:requestid) do
    desc 'Id of Constroller upgrade request.'
  end

  newparam(:comp_check_requestid) do
    desc 'Id of Constroller check compatibility request.'
  end


  newparam(:uploadendtime) do
    desc 'Firmware upload completion time'
  end


  newparam(:activateendtime) do
    desc 'Firmware activation completion time'
  end

  newparam(:version) do
    desc 'Firmware file version.'
  end

end
