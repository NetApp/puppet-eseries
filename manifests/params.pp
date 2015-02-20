# Class: netapp_e::params
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
class netapp_e::params {
  if $::puppetversion =~ /Puppet Enterprise/ {
    $owner = 'pe-puppet'
    $group = 'pe-puppet'
  } else {
    $owner = 'puppet'
    $group = 'puppet'
  }
  $mode = '0644'
}
