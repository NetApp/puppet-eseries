require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_host).provide(:netapp_e_host, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series hosts'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def self.instances
    response = transport.get_hosts
    response.each.collect do |host|
      new(:name => host['label'],
          :id => host['id'],
          :storagesystem => host['storagesystem'],
          :typeindex => host['hostTypeIndex'].to_s,
          :groupid => host['clusterRef'],
          :ports => host['hostSidePorts'],
          :initiators => host['initiators_ref_numbers'],
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

  def create
    request_body = { :name => resource[:name], :hostType => { :index => resource[:typeindex] } }
    if resource[:groupid]
      if resource[:groupid].is_a?(Hash)
        # search once more
        groupid = transport.host_group_id(resource[:storagesystem], resource[:groupid][:value])
        if groupid
          request_body['groupId'] = groupid
        else
          raise Puppet::Error, "Not found hostgroup #{resource[:groupid][:value]}"
        end
      else
        request_body['groupId'] = resource[:groupid]
      end
    end

    request_body['ports'] = resource[:ports] if resource[:ports]

    transport.create_host(resource[:storagesystem], request_body)
    Puppet.debug("Host #{resource[:name]} created")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_host: destroying host #{@resource[:name]}. \n")
    transport.delete_host(resource[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def groupid=(value)
    if resource[:groupid].is_a?(Hash)
      groupid = transport.host_group_id(resource[:storagesystem], resource[:groupid][:value])
      if groupid
        @property_flush[:groupid] = groupid
      else
        raise Puppet::Error, "Not found hostgroup #{resource[:groupid][:value]}"
      end
    else
      @property_flush[:groupid] = value
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def ports=(value)
    @property_flush[:ports] = value
  end

  def typeindex=(value)
    @property_flush[:typeindex] = value
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_e_disk_pool: checking existence of storage_pool #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def flush
    if not @property_flush.empty?
      request_body = {}
      request_body[:groupId] = @property_flush[:groupid] if @property_flush[:groupid]
      if @property_flush[:ports]
        request_body[:ports] = resource[:ports]
        request_body[:portsToRemove] = @property_hash[:initiators]
      end
      request_body[:hostType] = { :index => resource[:typeindex] } if @property_flush[:typeindex]
      transport.update_host(resource[:storagesystem], @property_hash[:id], request_body)
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
