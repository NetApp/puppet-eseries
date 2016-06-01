require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_firmware_file) do
  @doc = 'Manage Netapp E Storage Array Controller and NVSRAM firmware files'

  apply_to_device

  validate do
     raise Puppet::Error, 'You must specify a firmware file name.' unless @parameters.include?(:filename)
  end

  newparam(:name, :namevar => true) do
    desc 'Name of Firmware file manifest block.'
  end

  newparam(:filename) do
    desc 'Name of NVSRAM or Controller Firmware file name.'
    validate do | value | 
      raise Puppet::Error, 'Value of firmware file name must not be empty.' if value.strip() == ''
    end
  end
  
  newparam(:folderlocation) do
    desc 'Folder Location of NVSRAM or Controller Firmware file from where it is to be uploaded.'
    validate do | value |
      raise Puppet::Error, 'Value of folderlocation must not be empty.' if value.strip() == ''
    end
  end

  newproperty(:ensure) do
    desc 'present will ensure to upload firmware file to web proxy server. absent will ensure to delete Firmware file from the web proxy server.'
    defaultto :present

    def retrieve
      vart = provider.exists?
    rescue => detail
      raise Puppet::Error, "Error Message: #{detail}"
    end

    newvalue :present do
      raise Puppet::Error, 'You must specify a firmware folder location.' if @resource['folderlocation'] == nil or @resource['folderlocation'].to_s == '' 
      provider.upload
    end

    newvalue :absent do
      provider.delete
    end
  end

  newparam(:validate_file, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc 'Check if the Firmware file is valid or not.'
  end

  #Internal Use
  newparam(:version) do
    desc 'Firmware file version.'
  end
end
