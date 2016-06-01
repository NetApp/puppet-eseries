require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_web_proxy_upgrade).provide(:netapp_e_web_proxy_upgrade, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage Netapp E SANtiricity Web Proxy Server Upgrade'
  
  mk_resource_methods 

  def upgrade(stagefirmware)

    response = transport.download_web_proxy_update(@resource[:force])
    @resource[:correlationid] = response['correlationId']
    Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Webproxy upgrade download process started...")

    flag_for_check = true
    begin
      events_response = transport.get_events
      events = JSON.parse(events_response.body)
      events.each do |event|
          if event['correlationId'] == @resource[:correlationid]
            if event['status'] == 'success' and event['statusMessage'] == 'Updates downloaded'
              Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Webproxy new version downloaded successfully.")
              flag_for_check = false
              break
            elsif event['status'] == 'success' and event['statusMessage'] != 'Updates downloaded'
              fail("Puppet::Provider::Netapp_e_web_proxy_upgrade: #{event['statusMessage']}.")
              break
            elsif event['status'] == 'error'
              fail("Puppet::Provider::Netapp_e_web_proxy_upgrade: Error : #{event['statusMessage']}.")
              break
            else
              Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Waiting for 60 seconds to get status of download...")
              sleep(60)
            end
          end
      end
    end until flag_for_check==false
    
    upgrade_responce = transport.get_web_proxy_update
    if upgrade_responce['stagedVersions'].to_s == '[]'
      fail("Upgrade staged context #{upgrade_responce['stagedVersions']}. No update downloaded in staged version.")
    else
      staged_ver = upgrade_responce['stagedVersions'][0]['version']
      current_ver = upgrade_responce['currentVersions'][0]['version']
      if current_ver.to_s != staged_ver.to_s
        if stagefirmware == true
          Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Upgrade version #{upgrade_responce['stagedVersions'][0]['version']} staged susessfully.")
        else
          activate
          Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Upgrade version #{upgrade_responce['stagedVersions'][0]['version']} upgraded susessfully.")
        end
      else
        Puppet.debug("Current version and staged version are same.")
      end
    end

  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def activate

    upgrade_responce = transport.get_web_proxy_update
    if upgrade_responce['stagedVersions'].to_s == '[]'
      fail("Upgrade staged context #{upgrade_responce['stagedVersions']}. Staged version not available.")
    else
      staged_ver = upgrade_responce['stagedVersions'][0]['version']
      current_ver = upgrade_responce['currentVersions'][0]['version']
      if current_ver.to_s == staged_ver.to_s
        fail("Current version and staged version are same.")
      end
    end

    response = transport.reload_web_proxy_update
    @resource[:correlationid] = response['correlationId']
    Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Webproxy upgrade activation started susessfully.")

    flag_for_check = true
    begin
      events_response = transport.get_events
      if events_response.status == 200

        events = JSON.parse(events_response.body)
        events.each do |event|
            if event['correlationId'] == @resource[:correlationid]
              if(event['status'] == 'success')
                Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Webproxy upgrade activated successfully.")
                flag_for_check = false
                break
              end
            end
        end
      elsif events_response.status == 401
        transport.login
      else
        Puppet.debug("Puppet::Provider::Netapp_e_web_proxy_upgrade: Waiting for 60 seconds to retrive status of activation...")
        sleep(60)
      end
    end until flag_for_check==false

  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

end