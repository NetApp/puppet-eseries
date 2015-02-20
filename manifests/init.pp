# Class: netapp_e
#
# Deploy necessary component to manage NetApp E series storage arrays.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class netapp_e (
  $owner = $netapp_e::params::owner,
  $group = $netapp_e::params::group,
  $provider = $netapp_e::params::provider,
  $mode = $netapp_e::params::mode
) inherits netapp_e::params {
  if !defined(File["${settings::confdir}/device"]) {
    file { "${settings::confdir}/device":
      ensure => directory,
      owner  => $owner,
      group  => $group,
      mode   => $mode,
    }
  }
}
