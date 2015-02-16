require 'puppet/provider/netapp_e'
Puppet::Type.type(:netapp_e_snapshot_image).provide(:netapp_e_snapshot_image, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series snapshot image'

  def create
    sg_id = transport.get_snapshot_group_id(@resource[:storagesystem], @resource[:group])
    fail("Not found #{resource[:group]}") unless sg_id
    request_body = { :groupId => sg_id }
    transport.create_snapshot_image(resource[:storagesystem], request_body)
    Puppet.debug("#{resource[:name]} snapshot image created")
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
