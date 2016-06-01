# Class: netapp_e::web_proxy_params
#
# Define necessary operating system specific parameters which are required for installing SANtricity Web Proxy
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class netapp_e::web_proxy_params{
  $install_options_silent= '-i silent'
  $uninstall_options_silent= '-i silent'
  $uninstall_path = '/uninstall_web_services_proxy'
  #List of supported OS families
  $list_os_family = {'RedHat'=>'redhat','Suse'=>'suse','Solaris'=>'solaris','windows'=>'windows'}
  case $::osfamily {
    'RedHat':{
      $dependent_pck = ['*lsb']
      $service_name = 'web_services_proxy'
      $default_install_location = '/opt/netapp/santricity_web_services_proxy'
      $uninstall_cmd = 'uninstall_web_services_proxy'
      $uninstall_onlyif_prefix = 'test -e '
      $uninstall_onlyif_suffix = ' '
    }
    'Suse','Solaris':{
      $dependent_pck = ['lsb']
      $service_name = 'web_services_proxy'
      $default_install_location = '/opt/netapp/santricity_web_services_proxy'
      $uninstall_cmd = 'uninstall_web_services_proxy'
      $uninstall_onlyif_prefix = 'test -e '
      $uninstall_onlyif_suffix = ' '
    }
    'Windows':{
      $dependent_pck = []
      $service_name = 'NetAppWebServicesProxy'
      $default_install_location = 'C:/Program Files/NetApp/SANtricity Web Services Proxy'
      $uninstall_cmd = 'uninstall_web_services_proxy.exe'
      $uninstall_onlyif_prefix = 'cmd /c if not exist  '
      $uninstall_onlyif_suffix = ' exit 1'
    }
    default:{
      $dependent_pck = []
      $service_name = 'web_services_proxy'
      $default_install_location = '/opt/netapp/santricity_web_services_proxy'
      $uninstall_cmd = 'uninstall_web_services_proxy'
      $uninstall_onlyif_prefix = 'test -e '
      $uninstall_onlyif_suffix = ' '
    }
  }
}
