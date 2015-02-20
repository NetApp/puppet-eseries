require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_mirror_group).provide(:netapp_e_mirror_group, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series mirror group'

  mk_resource_methods

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def self.instances
    response = transport.get_mirror_groups
    response.each.collect do |mg|
      new(
        :name => mg['label'],
        :id => mg['groupRef'],
        :storagesystem => mg['storagesystem'],
        :role => mg['localRole'],
        :syncinterval => mg['syncIntervalMinutes'].to_s,
        :syncthreshold => mg['syncCompletionTimeAlertThresholdMinutes'].to_s,
        :recoverythreshold => mg['recoveryPointAgeAlertThresholdMinutes'].to_s,
        :repothreshold => mg['repositoryUtilizationWarnThreshold'].to_s,
        :ensure => :present
      )
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def self.prefetch(resources)
    instances.each do |prov|
      if resource = resources[prov.name]
        if resource[:primaryarray] == prov.storagesystem
          resource.provider = prov
        end
      end
    end
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_e_mirror_group: checking existence of mirror group #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end

  def create
    request_body = {
      :name => resource[:name],
      :secondaryArrayId => resource[:secondaryarray]
    }
    if resource[:syncinterval]
      request_body[:syncIntervalMinutes] = resource[:syncinterval]
      request_body[:recoveryWarnThresholdMinutes] = resource[:recoverythreshold]
      request_body[:repoUtilizationWarnThreshold] = resource[:repothreshold]
      request_body[:syncWarnThresholdMinutes] = resource[:syncthreshold]
    end
    request_body[:interfaceType] = resource[:interfacetype] if resource[:interfacetype]

    transport.create_mirror_group(resource[:primaryarray], request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_mirror_group: mirror group #{@resource[:name]} created successfully. \n")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_mirror_group: destroying mirror group #{@resource[:name]}. \n")
    transport.delete_mirror_group(@property_hash[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def syncinterval=(value)
    @property_flush[:syncIntervalMinutes] = value
  end

  def recoverythreshold=(value)
    @property_flush[:recoveryWarnThresholdMinutes] = value
  end

  def repothreshold=(value)
    @property_flush[:repoUtilizationWarnThreshold] = value
  end

  def syncthreshold=(value)
    @property_flush[:syncWarnThresholdMinutes] = value
  end

  def flush
    if not @property_flush.empty?
      request_body = {}
      request_body[:syncIntervalMinutes] = resource[:syncinterval]
      request_body[:recoveryWarnThresholdMinutes] = resource[:recoverythreshold]
      request_body[:repoUtilizationWarnThreshold] = resource[:repothreshold]
      request_body[:syncWarnThresholdMinutes] = resource[:syncthreshold]
      request_body[:name] = @property_hash[:name]
      transport.update_mirror_group(@property_hash[:storagesystem], @property_hash[:id], request_body)
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
