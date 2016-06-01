require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_flash_cache).provide(:netapp_e_flash_cache, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series flash cache'

  mk_resource_methods

  def suspend
    # To check specified that storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache: Storage System #{@resource[:storagesystem]} does not exist.")
    else
        # To get flash cache data of specified storage system
        flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
        # To check specified that flash cache exist or not
        if flash_cache_data['name'].to_s == @resource[:cachename].to_s
          # To check specified that flash cache is in suspended status 
          if flash_cache_data['flashCacheBase']['status'].to_s == "suspended" && @resource[:ignorestate] == false
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} already suspended.")
          elsif flash_cache_data['flashCacheBase']['status'] == "optimal"
            # Call suspend API
            transport.suspend_flash_cache(@resource[:storagesystem])
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} suspended successfully. \n")
          end
        else
          fail("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} does not exist. ")
        end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def resume
    # To check specified that storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache: Storage System #{@resource[:storagesystem]} does not exist.")
    else
        # To get flash cache data of specified storage system
        flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
        # To check specified that flash cache exist or not
        if flash_cache_data['name'].to_s == @resource[:cachename].to_s
          # To check specified that flash cache is in resumed status 
          if flash_cache_data['flashCacheBase']['status'].to_s == "optimal" && @resource[:ignorestate] == false
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} already resumed.")
          elsif flash_cache_data['flashCacheBase']['status'] == "suspended"
            # Call resume API
            transport.resume_flash_cache(@resource[:storagesystem])
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} resumed successfully. \n")
          end
        else
          fail("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} does not exist. ")
        end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def update
    # To check specified that storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache: Storage System #{@resource[:storagesystem]} does not exist.")
    else
        # To get flash cache data of specified storage system
        flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
        # To check specified that flash cache exist or not
        if flash_cache_data['name'].to_s == @resource[:cachename].to_s
          # To check specified that flash cache is in suspended status 
          if flash_cache_data['flashCacheBase']['status'].to_s == "optimal" 
            
            if @resource[:newname] && flash_cache_data['name'].to_s == @resource[:newname].to_s && @resource[:configtype] && flash_cache_data['flashCacheBase']['configType'].to_s == @resource[:configtype].to_s
              Puppet.debug("Puppet::Provider::netapp_e_flash_cache: New Name and config type for flash cache #{@resource[:cachename]} is already #{@resource[:newname]},#{@resource[:configtype]} as you specified. ")
            else
              updateFlag = 0
              # To check specified that flash cache name and new name are same or not 
              if @resource[:newname] && flash_cache_data['name'].to_s == @resource[:newname].to_s
                Puppet.debug("Puppet::Provider::netapp_e_flash_cache: New Name for flash cache #{@resource[:cachename]} is already #{@resource[:newname]} as you specified. ")  
              else
                updateFlag = 1
              end
              # To check specified that flash cache configtype and specified configtype are same or not 
              if @resource[:configtype] && flash_cache_data['flashCacheBase']['configType'].to_s == @resource[:configtype].to_s
                  Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Config type for flash cache #{@resource[:cachename]} is already #{@resource[:configtype]} as you specified. ")
              else        
                updateFlag = 1
              end  

              if updateFlag == 1
                  request_body = {}
                  request_body[:name] = @resource[:newname] if @resource[:newname]
                  request_body[:configType] = @resource[:configtype] if @resource[:configtype]
                  # To check specified that flash cache is in optimal status 
                  transport.update_flash_cache(@resource[:storagesystem],request_body)

                  # To print success message according to parameter provided
                  if @resource[:newname] && @resource[:configtype]
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]}, new name #{@resource[:newname]} and config type #{@resource[:configtype]} updated successfully. \n")
                  elsif @resource[:newname]
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]}, new name #{@resource[:newname]} updated successfully. \n")
                  elsif @resource[:configtype]
                    Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]}, config type #{@resource[:configtype]} updated successfully. \n")      
                  end 
              end
            end
            
          else
            fail("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} is in suspended status so updation can not be performed.")
          end
        else
          fail("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} does not exist.")
        end
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def delete
    # To check specified that storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache: Storage System #{@resource[:storagesystem]} does not exist.")
    else
        # To check specified that flash cache exist or not
        flash_cache_exist = transport.is_flash_cache_exist(@resource[:storagesystem])
        if flash_cache_exist == false
          Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} does not exist. ")
        else
          # To get flash cache data of specified storage system
          flash_cache_data = transport.get_flash_cache(@resource[:storagesystem])
          # To check specified that flash cache exist or not
          if flash_cache_data['name'].to_s == @resource[:cachename].to_s
            # To check specified that flash cache is in resumed status 
            transport.delete_flash_cache(@resource[:storagesystem])
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} deleted successfully. \n")
          else
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} does not exist. ")
          end
        end   
    end
    rescue => detail
      raise Puppet::Error, "#{detail}"
  end

  def create
    # To check specified that storage system exist or not
    is_exist = transport.get_storage_system(@resource[:storagesystem])
    if is_exist == false
        fail("Puppet::Provider::netapp_e_flash_cache: Storage System #{@resource[:storagesystem]} does not exist.")
    else
        # To check specified that flash cache exist or not
        flash_cache_data = transport.is_flash_cache_exist(@resource[:storagesystem])
        
        invalid_drives = Array.new
        if flash_cache_data == false
          invalid_drives = check_drives_validity
          if invalid_drives.size > 0
            fail("Puppet::Provider::netapp_e_flash_cache: flash cache #{@resource[:cachename]} can not be created as you specified invalid drive reference => #{invalid_drives.join(", ")} \n")
          else
            request_body ={}
            request_body[:cacheType] = "readOnlyCache"
            request_body[:driveRefs] = @resource[:diskids]
            request_body[:name] = @resource[:cachename]
            if @resource[:enableexistingvolumes] != nil
              request_body[:enableExistingVolumes] = @resource[:enableexistingvolumes]
            end
            #Puppet.debug(request_body)
            transport.create_flash_cache(@resource[:storagesystem],request_body)
            Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} created successfully. \n")         
          end
        elsif flash_cache_data['name'].to_s == @resource[:cachename].to_s
          Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Specified flash cache #{@resource[:cachename]} already exists. ")
        else
          Puppet.debug("Puppet::Provider::netapp_e_flash_cache: Only one flash cache can be created. ")
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
  