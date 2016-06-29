require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_flash_cache_drives).provide(:netapp_e_flash_cache_drives, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series flash cache'

  mk_resource_methods

  def exists?
   if @resource[:ensure] == :present
      :absent
   else
      :present
   end
  end

  def add
    found_drives = Array.new
    not_found_drives = Array.new
    invalid_drives = Array.new

    # To check if storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache_drives: Storage System #{@resource[:storagesystem]} does not exist. \n")
    else
        # To check that flash cache exist or not.
        flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
        if flash_cache_data['name'].to_s == @resource[:cachename].to_s 

            # To check that flash cache is in optimal status or not.
            if flash_cache_data['flashCacheBase']['status'].to_s == "optimal"

              # To check that specified drive reference is valid or not
              invalid_drives = check_drives_validity
              if invalid_drives.size > 0
                fail("Puppet::Provider::netapp_e_flash_cache_drives: No drive can be added to flash cache #{@resource[:cachename]} as you specified invalid drive reference => #{invalid_drives.join(", ")} \n")
              else
                if flash_cache_data['driveRefs'].size > 0
                    @resource[:diskids].each do |curdrv|
                      flag = false
                      flash_cache_data['driveRefs'].each do |drv|
                          if drv == curdrv
                            found_drives.push curdrv
                            flag = true
                            break
                          end
                      end
                      if !flag
                        not_found_drives.push curdrv
                      end
                    end
                end
                Puppet.debug("Drive(s) that is/are already added => #{found_drives.join(", ")} \n") if found_drives.size != 0
                Puppet.debug("Drive(s) that need to be added => #{not_found_drives.join(", ")} \n") if not_found_drives.size != 0
                request_body = {
                          :driveRef => not_found_drives,
                        }
                if not_found_drives.size == 0
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache_drives: Specified drive(s) is/are already added to flash cache #{@resource[:cachename]}. \n") 
                else
                    transport.flash_cache_add_drives(@resource[:storagesystem],request_body)
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache_drives: Specified drive(s) added to Flash Cache #{@resource[:cachename]} successfully. \n")
                end
              end
            else
              fail("Puppet::Provider::netapp_e_flash_cache_drives: Flash Cache status is suspended so drives can not be added. \n")
            end
        else
            fail("Puppet::Provider::netapp_e_flash_cache_drives: Flash Cache #{@resource[:cachename]} does not exist. \n")
        end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def remove
    found_drives = Array.new
    not_found_drives = Array.new
    invalid_drives = Array.new

    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache_drives: Storage System #{@resource[:storagesystem]} does not exist. \n")
    else
        flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
        # To check that flash cache exist or not
        if flash_cache_data['name'].to_s == @resource[:cachename].to_s 

            # To check that flash cache is in optimal status or not
            if flash_cache_data['flashCacheBase']['status'].to_s == "optimal"

              invalid_drives = check_drives_validity
              if invalid_drives.size > 0
                fail("Puppet::Provider::netapp_e_flash_cache_drives: No drive can be removed to flash cache #{@resource[:cachename]} as you specified invalid drive reference => #{invalid_drives.join(", ")} \n")
              else

                # To check that specified drive is already added
                if flash_cache_data['driveRefs'].size > 0

                  @resource[:diskids].each do |curdrv|
                    flag = false
                    flash_cache_data['driveRefs'].each do |drv|
                        if drv == curdrv
                          found_drives.push curdrv
                          flag = true
                          break
                        end
                    end

                    if !flag
                      not_found_drives.push curdrv
                    end

                  end
                end

                if flash_cache_data['driveRefs'].size - found_drives.size != 0
                  Puppet.debug("Drive(s) that need to be removed => #{found_drives.join(", ")} \n") if found_drives.size != 0
                  Puppet.debug("Drive(s) that is/are already removed => #{not_found_drives.join(", ")} \n") if not_found_drives.size != 0
                  request_body = {
                          :driveRef => found_drives,
                        }
                  if found_drives.size == 0
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache_drives: Specified drive(s) is/are already removed from Flash Cache #{@resource[:cachename]}. \n") 
                  else
                    transport.flash_cache_remove_drives(@resource[:storagesystem],request_body)
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache_drives: Specified drive(s) removed from Flash Cache #{@resource[:cachename]} successfully. \n")
                  end
                else
                  fail("Puppet::Provider::netapp_e_flash_cache_drives: All drive(s) can not be removed from flash cache. At least one drive must be present in flash cache. \n")
                end

              end

            else
              fail("Puppet::Provider::netapp_e_flash_cache_drives: Flash Cache #{@resource[:cachename]} status is suspended so drives can not be added. \n")
            end
        else
            fail("Puppet::Provider::netapp_e_flash_cache_drives: Flash Cache #{@resource[:cachename]} does not exist. \n")
        end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def check_drives_validity()
      # To check that specified drive reference is valid or not
      invalid_drives = Array.new
      all_drives = transport.get_drives(@resource[:storagesystem])
      
      @resource[:diskids].each do |curdrv|
          flag = false
          all_drives.each do |drv|
            if drv['driveRef'] ==  curdrv && drv['driveMediaType'].to_s == 'ssd'
              flag = true
              break
            end
          end
          if !flag
            invalid_drives.push curdrv
          end
      end
      invalid_drives
  end
  
end
  