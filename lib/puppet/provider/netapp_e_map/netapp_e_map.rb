require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_map).provide(:netapp_e_map, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series mapping'

  def destroy(sys_id, lun)
    map_id = transport.get_lun_mapping(sys_id, lun, false)
    transport.delete_lun_mapping(sys_id, map_id)
    Puppet.debug('Destroy lun mapping')
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def create(sys_id, source, target, type, lun)
    volumes = transport.get_volumes
    vol_id = false
    volumes.each do |vol|
      if vol['label'] == source and vol['storagesystem'] == sys_id
        vol_id = vol['id']
      end
    end

    request_body = { :mappableObjectId => vol_id, :lun => lun }

    if type == :host
      host_id = transport.host_id(sys_id, target)
      request_body[:targetId] = host_id
      transport.create_lun_mapping(sys_id, request_body)
      Puppet.debug('Create vol to host mapping')
    else
      hostgroup_id = transport.host_group_id(sys_id, target)
      request_body[:targetId] = hostgroup_id
      transport.create_lun_mapping(sys_id, request_body)
      Puppet.debug('Create vol to hostgroup mapping')
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
