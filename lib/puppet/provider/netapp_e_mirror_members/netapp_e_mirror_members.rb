require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_mirror_members).provide(:netapp_e_mirror_members, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series mirror members'

  def exist?
    Puppet.debug("Puppet::Provider::Netapp_e::Netapp_e_mirror_members: checking existence of #{name} pair members")
    volumes = transport.get_volumes
    volumes.each do |vol|
      if vol['label'] == @resource[:primaryvolume]
        @resource[:storagesystem] = vol['storagesystem']
        @resource[:primaryvolid] = vol['id']
        @resource[:primarypoolid] = vol['volumeGroupRef']
      elsif vol['label'] == @resource[:secondaryvolume]
        @resource[:secondvolid] = vol['id'] 
        @resource[:secondpoolid] = vol['volumeGroupRef']
      end
    end

    mirror_groups = transport.get_mirror_groups
    mirror_groups.each do |mg|
      if mg['label'] == @resource[:mirror] 
        @resource[:mirrorid] = mg['groupRef']
        break
      end
    end

    return :absent unless @resource[:mirrorid]

    members = transport.get_mirror_members(@resource[:storagesystem], @resource[:mirrorid])
    members.each do |m|
      if m['localVolume'] == @resource[:primaryvolid]
        @resource[:memberid] = m['memberRef']
        return :present 
      end
    end
    return :absent
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def create
    if not [ @resource[:storagesystem],
      @resource[:primaryvolid], 
      @resource[:secondvolid],
      @resource[:mirrorid]
    ].all?
      fail("Not all required entities discovered: pripool = #{@resource[:primarypoolid]}, \
             privol = #{@resource[:primaryvolid]}, secpool = #{@resource[:secondpoolid]}, \
             secvol = #{@resource[:secondvolid]}, mirror_group = #{@resource[:mirrorid]}")
    end

    request_body = {
      :primaryPoolId => @resource[:primarypoolid],
      :secondaryPoolId => @resource[:secondpoolid],
      :primaryVolumeRef => @resource[:primaryvolid],
      :secondaryVolumeRef => @resource[:secondvolid]
    }
    request_body[:percentCapacity] = resource[:capacity] if @resource[:capacity]
    request_body[:scanMedia] = resource[:scanmedia] unless @resource[:scanmedia].nil?
    request_body[:validateRepositoryParity] = resource[:validateparity] if @resource[:validateparity]

    transport.create_mirror_members(@resource[:storagesystem], @resource[:mirrorid], request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_mirror_members: mirror group #{@resource[:name]} created successfully. \n")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_mirror_members: destroying mirror members #{@resource[:name]}. \n")
    transport.delete_mirror_members(@resource[:storagesystem], @resource[:mirrorid], @resource[:memberid])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
