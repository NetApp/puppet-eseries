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
  $device_conf_dir = $netapp_e::params::device_conf_dir,
  $owner = $netapp_e::params::owner,
  $group = $netapp_e::params::group,
  $provider = $netapp_e::params::provider,
  $mode = $netapp_e::params::mode
) inherits netapp_e::params {


}
