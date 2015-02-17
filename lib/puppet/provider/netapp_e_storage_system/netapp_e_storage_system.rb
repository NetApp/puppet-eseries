require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_storage_system).provide(:netapp_e_storage_system, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series storage systems'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def self.instances
    response = transport.get_storage_systems

    response.each.collect do |storage_system|
      new(
        :name => storage_system['id'],
        :ensure => :present,
        :controllers => [storage_system['ip1'], storage_system['ip2']],
        :wwn => storage_system['wwn'],
        :meta_tags => storage_system['metaTags']
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

  def create
    request_body = { :id => resource[:name], :controllerAddresses => resource[:controllers], :metaTags => resource[:meta_tags], :password => resource[:password] }
    transport.create_storage_system(request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_storage_system: storage_system #{@resource[:name]} created successfully. \n")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_storage_system: destroying storage_system #{@resource[:name]}. \n")
    @property_flush[:ensure] = :absent
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_e_storage_system: checking existence of storage_system #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def meta_tags=(value)
    @property_flush[:meta_tags] = value
  end

  def flush
    if not @property_flush.empty?
      if @property_flush[:ensure] == :absent
        transport.delete_storage_system(resource[:name])
        return
      end
      request_body = {}
      request_body[:metaTags] = resource[:meta_tags] if @property_flush[:meta_tags]
      transport.update_storage_system(resource[:name], request_body)
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
