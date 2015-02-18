require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_volume_copy).provide(:netapp_e_volume_copy, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series volume'

  def create
    request_body = { 
      :sourceId => @resource[:sourceid], 
      :targetId => @resource[:targetid],
      :copyPriority => @resource[:copypriority]
    }
    request_body[:targetWriteProtected] = @resource[:targetwriteprotected] if @resource[:targetwriteprotected]
    request_body[:disablesnapshot] = @resource[:disablesnapshot] if @resource[:disablesnapshot]

    transport.create_volume_copy(@resource[:storagesystem], request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_volume_copy: volume copy #{@resource[:name]} created successfully. \n")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_volume_copy: destroying volume copy #{@resource[:name]}. \n")
    transport.delete_volume_copy(@resource[:storagesystem], @resource[:vcid])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def members_ids
    members = {}
    volumes = transport.get_volumes
    volumes.each do |vol|
      if vol['storagesystem'] == @resource[:storagesystem]
        members[:source] = vol['id'] if vol['label'] == @resource[:source]
        members[:target] = vol['id'] if vol['label'] == @resource[:target]
      end
    end
    notfound = []
    notfound << @resource[:source] unless members.has_key?(:source)
    notfound << @resource[:target] unless members.has_key?(:target)

    if notfound.empty?
      members
    else
      fail("Could not find id for #{notfound}")
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
