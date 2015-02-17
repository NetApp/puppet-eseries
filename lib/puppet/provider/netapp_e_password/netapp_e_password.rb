require 'puppet/provider/netapp_e'

Puppet::Type.type(:netapp_e_password).provide(:netapp_e_password, :parent => Puppet::Provider::Netapp_e) do
  @doc = 'Manage netapp e series storage array password'

  def passwords_status
    response = transport.get_passwords_status(resource[:storagesystem])
    if resource[:admin]
      if response['adminPasswordSet']
        Puppet.debug('Admin password is set')
        :set
      else
        Puppet.debug('Admin password is not set')
        :notset
      end
    else
      if response['readOnlyPasswordSet']
        Puppet.debug('RO password is set')
        :set
      else
        Puppet.debug('RO password is not set')
        :notset
      end
    end
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end

  def set_password
    request_body = {}
    request_body[:currentAdminPassword] = resource[:current]
    request_body[:adminPassword] = resource[:admin]
    request_body[:newPassword] = resource[:new]

    transport.change_password(resource[:storagesystem], request_body)
  rescue => detail
    raise Puppet::Error, "#{detail}"
  end
end
