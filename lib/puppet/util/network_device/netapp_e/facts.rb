require 'puppet/util/network_device/netapp_e'

class Puppet::Util::NetworkDevice::Netapp_e::Facts
  attr_reader :transport, :facts

  def initialize(transport)
    @transport = transport
  end

  def retrieve
    @facts = {}

    initialized_systems = []
    storagesystems = @transport.get_storage_systems

    storagesystems.each do |system|
      if system['status'] == 'optimal' or system['status'] == 'needsAttn'
        initialized_systems << system['id']
      end
    end

    @facts['initialized_systems'] = initialized_systems
    @facts
  end
end
