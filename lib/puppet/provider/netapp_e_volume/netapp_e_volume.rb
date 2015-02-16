require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_volume).provide(:netapp_e_volume, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series volume'

  mk_resource_methods

  def self.instances
    response = transport.get_volumes
    response.each.collect do |vol|
      new(
        :name => vol['name'],
        :id => vol['id'],
        :storagesystem => vol['storagesystem'],
        :mappings => vol['listOfMappings'],
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
    Puppet.debug("Puppet::Provider::Netapp_e_disk_pool: checking existence of storage_pool #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def create
    poolid = transport.storage_pool_id(resource[:storagesystem], resource[:storagepool])
    if resource[:thin] == :true
      request_body = {
        :poolId => poolid,
        :name => resource[:name],
        :sizeUnit => resource[:sizeunit],
        :virtualSize => resource[:size],
        :maximumRepositorySize => resource[:maxrepositorysize],
        :expansionPolicy => resource[:expansionpolicy],
        :createDefaultMapping => resource[:defaultmapping],
        :cacheReadAhead => resource[:cachereadahead],
        :repositorySize => resource[:repositorysize],
        :dataAssuranceEnabled => resource[:dataassurance]
      }
      request_body[:growthAlertThreshold] = resource[:growthalertthreshold] if resource[:growthalertthreshold]
      request_body[:owningControllerId] = resource[:owningcontrollerid] if resource[:owningcontrollerid]

      transport.create_thin_volume(resource[:storagesystem], request_body)
      Puppet.debug("Puppet::Provider::Netapp_e_volume: thinvolume #{@resource[:name]} created successfully. \n")
    else
      request_body = {
        :poolId => poolid,
        :name => resource[:name],
        :sizeUnit => resource[:sizeunit],
        :size => resource[:size],
        :segSize => resource[:segsize],
        :dataAssuranceEnabled => resource[:dataassurance]
      }
      transport.create_volume(resource[:storagesystem], request_body)
      Puppet.debug("Puppet::Provider::Netapp_e_volume: volume #{@resource[:name]} created successfully. \n")
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    if resource[:thin] == :true
      Puppet.debug("Puppet::Provider::Netapp_e_volume: destroying thin-volume #{@resource[:name]}. \n")
      transport.delete_thin_volume(resource[:storagesystem], @property_hash[:id])
    else
      Puppet.debug("Puppet::Provider::Netapp_e_volume: destroying volume #{@resource[:name]}. \n")
      transport.delete_volume(resource[:storagesystem], @property_hash[:id])
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
