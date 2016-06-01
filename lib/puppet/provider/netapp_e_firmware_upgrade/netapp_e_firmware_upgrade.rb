require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_firmware_upgrade).provide(:netapp_e_firmware_upgrade, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage Netapp E Storage Array Controller and NVSRAM firmware'
  
  mk_resource_methods 
  
  def exist?
    false
  end

  def upgrade(stagefirmware)
    
    #Get firmware file name and version of already uploaded firmware files. Fail if firware file not found on server.
    if @resource[:firmwaretype].to_s == 'cfwfile'
      Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Checking existence of firmware file #{@resource[:filename]} in web proxy server. \n")
      files = transport.get_firmware_files
      files.each do |file|
        if file['filename'] == @resource[:filename]
          @resource[:version] = file['version']
        end
      end
      if @resource[:version]
        Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Firmware file #{@resource[:filename]} found in web proxy server. \n")
      else
        fail("Firmware file #{@resource[:filename]} not found in web proxy server")
      end 
    end
    
    #Get firmware upgrade details for storage system. If any update running then fail execution.
    firmware_response = transport.get_firmware_upgrade_details(@resource[:storagesystem])
    if firmware_response.status == 200
      upgrade_response = JSON.parse(firmware_response.body)
      if upgrade_response['running'] != nil and upgrade_response['running']==true
        if upgrade_response['uploadCompletionPercentage'] != nil
          Puppet.debug("Upload Completion Percentage : #{upgrade_response['uploadCompletionPercentage']}%")
        end
        fail('Storage System upgrade process already running')
      end
    end

    @resource[:compatibilitycheck] = true if @resource[:compatibilitycheck].to_s == '' or  @resource[:compatibilitycheck].to_s.empty?
    @resource[:releasedbuildonly] = true if @resource[:releasedbuildonly].to_s == '' or  @resource[:releasedbuildonly].to_s.empty?

    #Check for version compatibility
    if @resource[:compatibilitycheck] == true
      
      comp_check_req_body = {
        :storageDeviceIds => [@resource[:storagesystem]],
        :releasedBuildsOnly => @resource[:releasedbuildonly],
      }
      comp_check_res = transport.check_firmware_compatibility(comp_check_req_body)
      @resource[:comp_check_requestid] = comp_check_res['requestId']
      
      comp_check_completed = false
      begin
        comp_file_result_found = false
        comp_status_res = transport.get_firmware_compatibility_check_status(@resource[:comp_check_requestid])
        if comp_status_res['requestId'] == @resource[:comp_check_requestid] and comp_status_res['checkRunning'] == false
          comp_check_completed = true
          results = comp_status_res['results']
          results.each do |result|
            if result['storageDeviceId'] == @resource[:storagesystem]
                
              #Check for cfwfile
              if @resource[:firmwaretype].to_s == 'cfwfile'
                cfwfiles = result['cfwFiles']
                cfwfiles.each do |cfwfile|
                  if cfwfile['filename'] == @resource[:filename]
                    comp_file_result_found = true
                    break
                  end
                end #End of loop
              end

              #Check for nvsramfile
              if @resource[:firmwaretype].to_s == 'nvsramfile'
                nvsramfiles = result['nvsramFiles']
                nvsramfiles.each do |nvsramfile|
                  if nvsramfile['filename'] == @resource[:filename]
                    comp_file_result_found = true
                    break
                  end
                end #End of loop
              end
            end #End of result['storageDeviceId'] == @resource[:storagesystem]
          end #End of loop
        else
          Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Waiting for 60 seconds to get status of compatibility check...")
          sleep(60)
        end #End of comp_status_res['requestId'] == @resource[:comp_check_requestid]
      end until comp_check_completed==true

      if comp_file_result_found == true
        Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Compatibility check for #{@resource[:filename]} done successfully.\n")
      else
        fail("Compatibility check for #{@resource[:filename]} failed.")
      end

    end #End of @resource[:compatibilitycheck] == true


    @resource[:melcheck] = false if @resource[:melcheck].to_s == '' or  @resource[:melcheck].to_s.empty?
    @resource[:waitforcompletion] = true if @resource[:waitforcompletion].to_s == '' or  @resource[:waitforcompletion].to_s.empty?

    isskipmelcheck = true
    if @resource[:melcheck] == true
      isskipmelcheck =false
    end
    request_body = {
      :stageFirmware => stagefirmware,
      :skipMelCheck => isskipmelcheck,
    }
    request_body[:cfwFile] = @resource[:filename] if @resource[:firmwaretype].to_s == 'cfwfile'
    request_body[:nvsramFile] = @resource[:filename] if @resource[:firmwaretype].to_s == 'nvsramfile'
    response = transport.upgrade_controller_firmware(@resource[:storagesystem], request_body)
    if response != nil
          @resource[:requestid]=response['requestId']
          if stagefirmware == false
            Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware upgrade request submitted successfully with request id #{@resource[:requestid]}. \n")
          else
            Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware stage request submitted successfully with request id #{@resource[:requestid]}. \n")
          end

          if @resource[:waitforcompletion] == true
            flag_for_check = true
            begin
              firmware_response = transport.get_firmware_upgrade_details(@resource[:storagesystem])
              if firmware_response.status == 200
                upgrade_response = JSON.parse(firmware_response.body)
                if upgrade_response['uploadCompletionPercentage'] != nil and upgrade_response['uploadCompletionTime'] == nil
                  Puppet.debug(" Waiting for 60 seconds to check UPLOAD status.....Upload Completion Percentage : #{upgrade_response['uploadCompletionPercentage']}%")
                end
                if stagefirmware == false and upgrade_response['activationStartTime'] != nil
                  Puppet.debug(" Waiting for 60 seconds to check ACTIVATION status.....Activation StartTime : #{upgrade_response['activationStartTime']}")
                end
                if upgrade_response['running'] != nil and upgrade_response['running'] == false
                  flag_for_check = false
                  @resource[:uploadendtime] = upgrade_response['uploadCompletionTime'] if upgrade_response['uploadCompletionTime'] != nil
                  @resource[:activateendtime] = upgrade_response['activationCompletionTime'] if upgrade_response['activationCompletionTime'] != nil
                  break
                end
              else
                fail (firmware_response.body)
              end
              sleep(60)
            end until flag_for_check==false

            if stagefirmware == false
              Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware upgrade request completed successfully with request id #{@resource[:requestid]} at #{@resource[:activateendtime]}. \n")
            else
              Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware stage request completed successfully with request id #{@resource[:requestid]} at #{@resource[:uploadendtime]}. \n")
            end
          end
    else
       fail ("Error while upgrading the storage array #{@resource[:storagesystem]}")    
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def activate

    if @resource[:firmwaretype].to_s == 'cfwfile'
      firmware_response = transport.get_firmware_upgrade_details(@resource[:storagesystem])
      if firmware_response.status == 200
        upgrade_response = JSON.parse(firmware_response.body)
        if upgrade_response['running'] != nil and upgrade_response['running'] == true
          fail("Some process is running on server. Can not activate staged firmware now.")
        end
      end

      @resource[:melcheck] = false if @resource[:melcheck].to_s == '' or  @resource[:melcheck].to_s.empty?
      @resource[:waitforcompletion] = true if @resource[:waitforcompletion].to_s == '' or  @resource[:waitforcompletion].to_s.empty?

      isskipmelcheck = true
      if @resource[:melcheck] == true
        isskipmelcheck = false
      end
      request_body = {
        :skipMelCheck => isskipmelcheck
      }
      response = transport.activate_controller_firmware(@resource[:storagesystem], request_body)
      if response != nil
          @resource[:requestid]=response['requestId']
          Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware activation request submitted successfully with request id #{@resource[:requestid]}. \n")

          if @resource[:waitforcompletion] == true
            flag_for_check = true
            begin
              firmware_response = transport.get_firmware_upgrade_details(@resource[:storagesystem])
              if firmware_response.status == 200
                upgrade_response = JSON.parse(firmware_response.body)
                if upgrade_response['activationStartTime'] != nil
                  Puppet.debug(" Waiting for 60 seconds to check ACTIVATION status.....Activation StartTime : #{upgrade_response['activationStartTime']}")
                end
                if upgrade_response['running'] != nil and upgrade_response['running'] == false
                  flag_for_check = false
                  @resource[:activateendtime] = upgrade_response['activationCompletionTime'] if upgrade_response['activationCompletionTime'] != nil
                  break
                end
              else
                fail (firmware_response.body)
              end
              sleep(60)
            end until flag_for_check==false

            Puppet.debug("Puppet::Provider::Netapp_e_firmware_upgrade: Storage Array #{@resource[:storagesystem]} firmware activation request completed successfully with request id #{@resource[:requestid]} at #{@resource[:activateendtime]}. \n")
          end
      else
        fail ("Error while activating staged firmware for storage array #{@resource[:storagesystem]}")
      end
    else
      fail(raise Puppet::Error, 'Activate firmware operation not supported for nvsram file type.')
    end

  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end