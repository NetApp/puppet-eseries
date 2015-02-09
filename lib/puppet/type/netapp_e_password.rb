require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_password) do
  @doc = 'Manage Netapp E series storage array password'

  apply_to_device

  newparam(:storagesystem, :namevar => true) do
    desc 'Storage system id'
  end

  newparam(:current) do
    desc 'Current admin password'
  end

  newparam(:new) do
    desc 'New password'
  end

  newproperty(:ensure) do
    desc 'Check if particular type of password is set up'
    defaultto :set

    def retrieve
      if resource[:force] == :true
        Puppet.debug('Password change forced')
        :notset
      else
        Puppet.notice('check password existence')
        provider.passwords_status
      end
    end

    newvalue :notset
    newvalue :set do
      provider.set_password
    end
  end

  newparam(:admin) do
    desc 'If this is true, this will set the admin password, if false, it sets the RO password'
    newvalues(:true, :false)
  end

  newparam(:force) do
    desc 'If true it will always try change password, even if already set. We can not check if passwords match'
    newvalues(:true, :false)
    defaultto :false
  end
end
