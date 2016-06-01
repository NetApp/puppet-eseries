require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_consistency_group).provide(:netapp_e_consistency_group, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series consistency groups'
  
  mk_resource_methods
  
  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  def exist?
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_group: Checking existence of consistency group #{@resource[:consistencygroup]}. \n")
    response = transport.get_consistency_groups
    response.each.collect do |cg|
      if cg['label'] == resource[:consistencygroup] and cg['storagesystem'] == resource[:storagesystem]
        @property_hash[:consistencygroup] = cg['label']
        @property_hash[:id] = cg['cgRef']
        @property_hash[:storagesystem]  = cg['storagesystem']
        @property_hash[:repositoryfullpolicy]  = cg['repFullPolicy']
        @property_hash[:fullwarnthresholdpercent]  = cg['fullWarnThreshold'].to_s
        @property_hash[:autodeletethreshold]  = cg['autoDeleteLimit'].to_s
        @property_hash[:rollbackpriority]  = cg['rollbackPriority']
        return :present
      end
    end
    return :absent
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

 def create
    request_body = { 
      :name  => resource[:consistencygroup]
    }
    request_body[:fullWarnThresholdPercent]  = resource[:fullwarnthresholdpercent] if resource[:fullwarnthresholdpercent]
    request_body[:autoDeleteThreshold] = resource[:autodeletethreshold] if resource[:autodeletethreshold]
    request_body[:repositoryFullPolicy] = resource[:repositoryfullpolicy] if resource[:repositoryfullpolicy]
    request_body[:rollbackPriority]  = resource[:rollbackpriority] if resource[:rollbackpriority]
    transport.create_consistency_group(resource[:storagesystem],request_body)
    Puppet.debug("Puppet::Provider::Netapp_e_consistency_group: Consistency group #{@resource[:consistencygroup]} created successfully.")

  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def fullwarnthresholdpercent=(value)
    @property_flush[:fullwarnthresholdpercent] = value
  end

  def autodeletethreshold=(value)
    @property_flush[:autodeletethreshold] = value
  end

  def repositoryfullpolicy=(value)
    @property_flush[:repositoryfullpolicy] = value
  end

  def rollbackpriority=(value)
    @property_flush[:rollbackpriority] = value
  end

  def flush
    if not @property_flush.empty?
      if @property_flush[:ensure] == :absent
        transport.delete_consistency_group(resource[:storagesystem], @property_hash[:id])
        Puppet.debug("Puppet::Provider::Netapp_e_consistency_group: Consistency group #{@resource[:consistencygroup]} deleted successfully.")
        return

      else
        request_body = {}
        request_body[:fullWarnThresholdPercent] = resource[:fullwarnthresholdpercent] if resource[:fullwarnthresholdpercent]
        request_body[:autoDeleteThreshold] = resource[:autodeletethreshold] if resource[:autodeletethreshold]
        request_body[:repositoryFullPolicy] = resource[:repositoryfullpolicy] if resource[:repositoryfullpolicy]
        request_body[:rollbackPriority] = resource[:rollbackpriority] if resource[:rollbackpriority]
        request_body[:name] = resource[:consistencygroup]

        transport.update_consistency_group(resource[:storagesystem], @property_hash[:id], request_body)
        Puppet.debug("Puppet::Provider::Netapp_e_consistency_group: Consistency group #{@resource[:consistencygroup]} updated successfully.")
        return

      end
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
  
end