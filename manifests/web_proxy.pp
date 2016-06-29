# Class: netapp_e::web_proxy
#
# This defined resource type will create an install NetApp E-Series SANtricity Web Proxy Server on the Puppet Agent node.
#
# Parameters:
#
# [*ensure*] - Ensure that netappweb_service will be installed or absent
# [*install_file_name*] - Name of the installation file inside the folder named files in the module
# [*install_file_location*] - Location where the installation file will be copied
# [*install_dependent_packages*] - Enable or disable installation of dependent packages
#
# Actions:
# 
# Requires:
#
# Sample Usage:
#
#   #Install on Linux:
#   class { 'netapp_e::web_proxy':
#     ensure 	      				      => 'present',
#     install_file_name			      => 'webservice-01.20.7000.0005.bin', #Web Proxy Installation file kept in modules/netapp_e/files
#     install_file_location		    => '/opt', #This folder must exist
# 	  install_dependent_packages	=> 'yes',
#   }
#
#   #Uninstall on Linux:
#   class { 'netapp_e::web_proxy':
#     ensure 	  => 'absent',
#   }
#   
#   #Install on windows
#   class { 'netapp_e::web_proxy':
#     ensure						          => 'installed',
#     install_file_name			      => 'webservice-01.20.3000.0005.exe', #Web Proxy Installation file kept in modules/netapp_e/files
#     install_file_location		    => 'H:/setup', #This folder must exist
# 	  install_dependent_packages  => 'no',
#   }
#
#   #Uninstall on winodws
#   netapp_e::web_proxy { 'netapp_e::web_proxy':
#     ensure    => 'uninstalled',
#   }
#
class netapp_e::web_proxy(
  $install_file_name,
  $install_file_location,
  $ensure      = 'installed',    # Possible values : 'installed'->To install,'absent'->To Uninstall
  $install_dependent_packages  = 'no',
){
  include netapp_e::web_proxy_params

  $list_os_family = $netapp_e::web_proxy_params::list_os_family
  
  #Check if node operating system is supported or not for this module
  if has_key($list_os_family, $::osfamily){

    $operatingsys = $list_os_family[$::osfamily]
    $install_options_silent = $netapp_e::web_proxy_params::install_options_silent
    $uninstall_options_silent = $netapp_e::web_proxy_params::uninstall_options_silent
    $install_cmd = "${install_file_location}/${install_file_name}"
    $uninstall_path = "${netapp_e::web_proxy_params::default_install_location}${netapp_e::web_proxy_params::uninstall_path}"
    $uninstall_cmd = "${uninstall_path}/${netapp_e::web_proxy_params::uninstall_cmd}"
    $uninstall_onlyif_prefix = $netapp_e::web_proxy_params::uninstall_onlyif_prefix
    $uninstall_onlyif_suffix = $netapp_e::web_proxy_params::uninstall_onlyif_suffix
    $uninstall_onlyif = "${uninstall_onlyif_prefix} \"${uninstall_path}\" ${uninstall_onlyif_suffix}"
    $service_name = $netapp_e::web_proxy_params::service_name
    
    if ($ensure == 'installed') or ($ensure == 'present') {
        #Copy installtion file from netapp_e module to install location
        file { 'installation_file':
          ensure  => file,
          path    => $install_cmd,
          replace => no,
          mode    => '0777',
          source  => "puppet:///modules/netapp_e/${install_file_name}",
      }->
      #Install the package from install location
      exec { 'install_netapp_web':
        command => "${install_cmd} ${install_options_silent}",
        path    => $install_file_location,
        cwd     => $install_file_location,
        creates => $uninstall_path,
      }
      
      if $::osfamily != 'windows' and  $install_dependent_packages != 'no' {

          # Dependent package will install to start proxy service
          $packs = $netapp_e::web_proxy_params::dependent_pck
          each($packs) |$loop| {
            package{ $loop :
              ensure  => installed,
              require => Exec['install_netapp_web'],
            }
          }        
      }

      #Enables and starts service
      service { $service_name:
          ensure  => running,
          enable  => true,
          require => Exec['install_netapp_web'],
        }->
        notify {'SANtricity Web Proxy installed successfully.':}
    }
    elsif  ($ensure == 'uninstalled') or ($ensure == 'absent'){
      
      #Execute uninstalltion command of proxy service
      exec { 'uninstall_netapp_web' :
        command => "\"${uninstall_cmd}\" ${uninstall_options_silent}",
        onlyif  =>  "${uninstall_onlyif}",
        path    => $::path,
      }->
      notify {'SANtricity Web Proxy uninstalled successfully.':}
    }
    else{
      #Prompt message if ensure value other then installed and absent
      notify {"Invalid Parameter Specified: ${ensure}. Allowed values are installed and absent.":}
    }
  }else{
    notify {"This module not supported for ${::osfamily} operating system family.":}
  }
}