require 'puppet/provider'
require 'puppet/util/network_device/netapp_e/device'

class Puppet::Provider::Netapp_e < Puppet::Provider
  def self.transport
    if Facter.value(:url)
      Puppet.debug 'Puppet::Util::NetworkDevice::Netapp_e: connecting via facter url.'
      @device ||= Puppet::Util::NetworkDevice::Netapp_e::Device.new(Facter.value(:url))
    else
      @device ||= Puppet::Util::NetworkDevice.current
      raise Puppet::Error, "Puppet::Util::NetworkDevice::Netapp_e: device not initialized #{caller.join("\n")}" unless @device
    end
    @tranport = @device.transport
  end

  def transport
    # this calls the class instance of self.transport instead of the object instance which causes an infinite loop.
    self.class.transport
  end
end
