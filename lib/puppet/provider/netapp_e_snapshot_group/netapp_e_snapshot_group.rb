require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_snapshot_group).provide(:netapp_e_snapshot_group, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series snapshot groups'

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  mk_resource_methods

  def self.instances
    response = transport.get_snapshot_groups
    response.each.collect do |sg|
      new(
        :name => sg['label'],
        :id => sg['id'],
        :storagesystem => sg['storagesystem'],
        :warnthreshold => sg['fullWarnThreshold'].to_s,
        :policy => sg['repFullPolicy'],
        :limit => sg['autoDeleteLimit'].to_s,
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
    Puppet.debug("Puppet::Provider::Netapp_snapshot_group: checking existence of snapshot group #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def create
    sp_id = transport.storage_pool_id(resource[:storagesystem], resource[:storagepool])
    volumes = transport.get_volumes
    vol_id = false
    volumes.each do |vol|
      if vol['label'] == resource[:volume] and vol['storagesystem'] == resource[:storagesystem]
        vol_id = vol['id']
      end
    end

    if sp_id and vol_id
      request_body = {
        :name => resource[:name],
        :baseMappableObjectId => vol_id,
        :storagePoolId => sp_id,
        :repositoryPercentage => resource[:repositorysize],
        :warningThreshold => resource[:warnthreshold],
        :fullPolicy => resource[:policy],
        :autoDeleteLimit => resource[:limit]
      }
      transport.create_snapshot_group(resource[:storagesystem], request_body)
      Puppet.debug("#{resource[:name]} snapshot group created")
    else
      raise Puppet::Error, "Unable to retrieve required informations for creating #{resource[:name]} snapshot group"
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Trying to destroy #{resource[:name]} snapshot group")
    transport.delete_snapshot_group(resource[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def warnthreshold=(value)
    @property_flush[:warnthreshold] = value
  end

  def limit=(value)
    @property_flush[:limit] = value
  end

  def policy=(value)
    @property_flush[:policy] = value
  end

  def flush
    if not @property_flush.empty?
      request_body = {}
      request_body[:warningThreshold] = @property_flush[:warnthreshold] if @property_flush[:warnthreshold]
      request_body[:fullPolicy] = @property_flush[:policy] if @property_flush[:policy]
      request_body[:autoDeleteLimit] = @property_flush[:limit] if @property_flush[:limit]

      transport.update_snapshot_group(resource[:storagesystem], @property_hash[:id], request_body)
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
