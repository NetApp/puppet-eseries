require 'puppet/util/network_device'
Puppet::Type.newtype(:netapp_e_network_interface) do
  @doc = 'Manage Netapp E series management network configuration'

  apply_to_device

  validate do
    raise Puppet::Error, 'You must specify a mac address of interface.' unless @parameters.include?(:macaddr)
    raise Puppet::Error, 'You must specify a storage system.' unless @parameters.include?(:storagesystem)
  end

  def self.valid_ipv4?(addr)
    if /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/ =~ addr
      return $~.captures.all? {|i| i = i.to_i; i >= 0 and i <= 255 }
    end
    return false
  end

  def self.valid_ipv6?(addr)
    # http://forums.dartware.com/viewtopic.php?t=452
    # ...and, yes, it is this hard. Doing it programatically is harder.
    return true if addr =~ /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/
    false
  end

  newparam(:macaddr, :namevar => true) do
    desc 'An ASCII string representation of the globally-unique 48-bit MAC address assigned to the Ethernet interface.'
    validate do |value|
      fail("#{value} is not valid mac address use '0123456789AB' form") unless value =~ /^[a-fA-F0-9]{12}$/
    end
  end

  newproperty(:id, :readonly => true) do
    desc 'interfaceRef: Reference to the Ethernet interface to configure.'
  end

  newproperty(:controller, :readonly => true) do
    desc 'controllerRef: Reference to the controller.'
  end

  newparam(:storagesystem) do
    desc 'ID of storage system.'
  end

  newproperty(:interfacename, :readonly => true) do
    desc 'Name of Ethernet port'
  end

  newproperty(:ipv4) do
    desc 'True if ipv4 is to be enabled for this interface; otherwise false.'
    newvalues(:true, :false)
  end

  newproperty(:ipv4address) do
    desc 'The ipv4 address for the interface. Required for static configuration.'

    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv4?(value)
    end
  end

  newproperty(:ipv4mask) do
    desc 'The ipv4 subnet mask for the interface. Required for static configuration.'

    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv4?(value)
    end
  end

  newproperty(:ipv4gateway) do
    desc 'Manually specify the address of the gateway.'

    validate do |value|
      fail("#{value} is not a valid IPv4 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv4?(value)
    end
  end

  newproperty(:ipv4config) do
    desc 'Setting that determines how the ipv4 address is configured. Required if ipv4 is enabled.'
    newvalues('configDhcp', 'configStatic', '__UNDEFINED')
  end

  newproperty(:ipv6) do
    desc 'True if ipv6 is to be enabled for this interface; otherwise false.'
    newvalues(:true, :false)
  end

  newparam(:ipv6address) do
    desc 'The ipv6 local address for the interface.'

    validate do |value|
      fail("#{value} is not a valid IPv6 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv6?(value)
    end
  end

  newproperty(:ipv6config) do
    desc 'The method by which the ipv6 address information is configured for the interface.'
    newvalues('configStatic', 'configStateless', '__UNDEFINED')
  end

  newparam(:ipv6gateway) do
    desc 'Manually specify the address of the gateway.'

    validate do |value|
      fail("#{value} is not a valid IPv6 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv6?(value)
    end
  end

  newparam(:ipv6routableaddr) do
    validate do |value|
      fail("#{value} is not a valid IPv6 address") unless Puppet::Type::Netapp_e_network_interface.valid_ipv6?(value)
    end
  end

  newproperty(:remoteaccess) do
    desc 'If set to true, the controller is enabled for establishment of a remote access session.
        Depending on the controller platform, the method for remote access could be rlogin or telnet.'
    newvalues(:true, :false)
  end

  newproperty(:speed) do
    desc 'The configured speed setting for the Ethernet interface.'
    newvalues('speedNone', 'speedAutoNegotiated', 'speed10MbitHalfDuplex',
              'speed10MbitFullDuplex', 'speed100MbitHalfDuplex', 'speed100MbitFullDuplex',
              'speed1000MbitHalfDuplex', 'speed1000MbitFullDuplex', '__UNDEFINED'
             )
  end
end
