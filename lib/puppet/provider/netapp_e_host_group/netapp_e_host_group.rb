require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_host_group).provide(:netapp_e_host_group, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series host groups'

  mk_resource_methods

  def self.instances
    response = transport.get_host_groups
    response.each.collect do |hg|
      new(
        :name => hg['label'],
        :id => hg['id'],
        :storagesystem => hg['storagesystem'],
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
    request_body = { :name => resource[:name], :hosts => resource[:hosts] }
    transport.create_host_group(resource[:storagesystem], request_body)
    Puppet.debug("Host group #{resource[:name]} created")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def destroy
    Puppet.debug("Puppet::Provider::Netapp_e_host_group: destroying host group #{@resource[:name]}. \n")
    transport.delete_host_group(resource[:storagesystem], @property_hash[:id])
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def exists?
    Puppet.debug("Puppet::Provider::Netapp_host_group: checking existence of host group #{@resource[:name]}. \n")
    @property_hash[:ensure] == :present
  end
end
