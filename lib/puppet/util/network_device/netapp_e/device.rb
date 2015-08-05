require 'puppet/util/network_device'
require 'puppet/util/network_device/netapp_e'
require 'puppet/util/network_device/netapp_e/facts'
require 'puppet/util/network_device/netapp_e/netapp_e_series_api'
require 'uri'

class Puppet::Util::NetworkDevice::Netapp_e::Device
  attr_accessor :url, :transport

  def initialize(url, option = {})
    @url = URI.parse(url)
    redacted_url = @url.dup
    redacted_url.password = '****' if redacted_url.password

    Puppet.debug("Puppet::Device::Netapp: connecting to Netapp device #{redacted_url}")

    raise ArgumentError, "Invalid scheme #{@url.scheme}. Must be http or https." unless (@url.scheme == 'https' || @url.scheme == 'http')
    raise ArgumentError, 'no user specified' unless @url.user
    raise ArgumentError, 'no password specified' unless @url.password

    @transport ||= NetApp::ESeries::Api.new(@url.user, @url.password, "#{@url.scheme}://#{@url.host}:#{@url.port}#{@url.path.chomp('/')}", true, 15)

    @transport.login

    # post presence of Puppet module to key/value pair for ASUP posting
    client_info = {
        'application' => 'Puppet',
        'app-version' => Facter.value(:puppetversion),
        'url'         => redacted_url
    }.to_json

    @transport.post_key_value('Puppet', client_info)
  end

  def facts
    @facts ||= Puppet::Util::NetworkDevice::Netapp_e::Facts.new(@transport)
    facts = @facts.retrieve

    facts
  end
end
