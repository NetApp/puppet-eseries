require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_storage_pool).provide(:netapp_e_storage_pool, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series storage pools'

  mk_resource_methods

  def self.instances
    response = transport.get_storage_pools
    response.each.collect do |pool|
      new(
        :name => pool['label'],
        :id => pool['id'],
        :storagesystem => pool['storagesystem'],
        :raidlevel => pool['raidLevel'],
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
    request_body = { :raidLevel => resource[:raidlevel], :name => resource[:name], :diskDriveIds => resource[:diskids], :erasedrives => resource[:erasedrives]  }
    transport.create_storage_pool(resource[:storagesystem], request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_storage_pool: storage_pool #{@resource[:name]} created successfully. \n")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_storage_pool: destroying storage_pool #{@resource[:name]}. \n")
    transport.delete_storage_pool(resource[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
