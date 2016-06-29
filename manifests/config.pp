# Defined Resource Type: netapp_e::config
#
# This defined resource type will create an netapp_e device configuration file
# to be used with Puppet.
#
# Parameters:
#
# [*username*] - The username used to connect to the SANtricity Web Proxy
# [*password*] - The password used to connect to the SANtricity Web Proxy
# [*url*] - The url to the SANtricity Web Proxy. DO NOT INCLUDE https://
# [*port*] - The port number on which the SANtricity Web Proxy listen.
# [*target*] - The path to the netapp configuration file we are creating
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
# netapp_e::config { 'netapp':
#   username => 'rw',
#   password => 'rw',
#   url      => 'proxy.netapp.local',
#   port     => '8080'
#   target   => '/etc/puppetlabs/puppet/device/netapp.conf
# }
#
define netapp_e::config(
  $username = 'rw',
  $password = 'rw',
  $protocol = 'http',
  $port = '8080',
  $url = $name,
  $target = "${netapp_e::device_conf_dir}/device/${name}.conf",
) {
  include netapp_e

  $owner = $netapp_e::owner
  $group = $netapp_e::group
  $mode = $netapp_e::mode

  if !defined(File["${netapp_e::device_conf_dir}/device"]) {
    file { "${netapp_e::device_conf_dir}/device":
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
  }
  
  file { "${target}":
    ensure  => present,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    content => template('netapp_e/config.erb'),
  }
}
