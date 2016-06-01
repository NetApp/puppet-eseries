require 'puppet/provider/netapp_e'
require 'fileutils'

Puppet::Type.type(:netapp_e_firmware_file).provide(:netapp_e_firmware_file, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage Netapp E Storage Array Controller and NVSRAM firmware files'
  
  mk_resource_methods 

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_e_firmware_file: Checking existence of firmware file #{@resource[:filename]} in web proxy server. \n")
    
    #Get firmware file name and version of already uploaded firmware files
    files = transport.get_firmware_files
    files.each do |file|
      if file['filename'] == @resource[:filename]
        @resource[:version] = file['version']
      end
    end

    if @resource[:version]
      return :present
    end
    
    return :absent  

  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def upload

    file_path = "#{@resource[:folderlocation]}/#{@resource[:filename]}"
    if File.file?(file_path) == false
      fail("Firmware file #{@resource[:filename]} not found at '#{@resource[:folderlocation]}'.")
    end

    @resource[:validate_file] = true if @resource[:validate_file].to_s == '' or  @resource[:validate_file].to_s.empty?
    response=transport.upload_firmware_file(file_path,@resource[:validate_file])
    if response['fileName'] != @resource[:filename]
      fail("Error while uploading Firmware file #{@resource[:filename]}")
    end

    Puppet.debug("Puppet::Provider::Netapp_e_firmware_file: Firmware file #{@resource[:filename]}  uploaded successfully.")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def delete

    fail("Puppet::Provider::Netapp_e_firmware_file: File #{@resource[:filename]} does not exist.") unless resource[:version]
    transport.delete_firmware_file(@resource[:filename])
    Puppet.debug("Puppet::Provider::Netapp_e_firmware_file: Firmware file #{@resource[:filename]}  deleted successfully.")
  
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end