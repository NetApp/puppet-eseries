require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_snapshot_volume).provide(:netapp_e_snapshot_volume, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series snapshot volume'

  mk_resource_methods

  def self.instances
    response = transport.get_snapshot_volumes
    response.each.collect do |vol|
      new(
        :name => vol['name'],
        :id => vol['id'],
        :storagesystem => vol['storagesystem'],
        :fullthreshold => vol['fullWarnThreshold'].to_s,
        :ensure => :present
      )
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        resource.provider = prov
      end
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_e_snapshot_volume: checking existence of snapshot volume #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def create
    poolid = transport.storage_pool_id(resource[:storagesystem], resource[:storagepool])
    request_body = { 
      :snapshotImageId => @resource[:imageid],
      :name => @resource[:name],
      :viewMode => @resource[:viewmode],
      :repositoryPoolId => poolid
    }
    request_body[:fullThreshold] = @resource[:fullthreshold] if @resource[:fullthreshold]
    request_body[:repositoryPercentage] = @resource[:repositorysize] if @resource[:repositorysize]

    transport.create_snapshot_volume(@resource[:storagesystem], request_body)
    Puppet.debug("Snapshot volume #{@resource[:name]} created")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_snapshot_volume: destroying snapshot volume #{@resource[:name]}. \n")
    transport.delete_snapshot_volume(resource[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def fullthreshold=(value)
    request_body = { :fullThreshold => value }
    transport.update_snapshot_volume(@resource[:storagesystem], @property_hash[:id], request_body)
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
