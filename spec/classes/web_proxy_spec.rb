require 'spec_helper'

describe 'netapp_e::web_proxy', :type => :class  do

  	context 'should install web_proxy with RedHat os family' do
  			
  		let(:facts) { {:osfamily => 'RedHat', :operatingsystem => 'Centos'} }
  		let(:params) { {:install_file_name => 'web_proxy.bin',:install_file_location => '/root',:ensure => "installed",:install_dependent_packages => "yes",} }

  		it { should contain_class('netapp_e::web_proxy_params') }

	  	it do should contain_file('installation_file').with(
	        'ensure'  => 'file',
	        'path'    => '/root/web_proxy.bin',
	        'replace' => 'no',
	        'mode'    => '0777',
	        'source'  => 'puppet:///modules/netapp_e/web_proxy.bin',
	    ) end

	  	it do should contain_exec('install_netapp_web').with(
          'command' => '/root/web_proxy.bin -i silent',
	        'path'    => '/root',
	        'cwd'     => '/root',
	        'creates' => '/opt/netapp/santricity_web_services_proxy/uninstall_web_services_proxy',
        ) end

	  	it do should contain_package('*lsb').with(
            'ensure'  => 'installed',
            'require' => 'Exec[install_netapp_web]',
        ) end

	  	it do should contain_service('web_services_proxy').with(
            'require' => 'Exec[install_netapp_web]',
            'enable'  => 'true',
            'ensure'  => 'running'
        ) end
  	end

  	context 'should uninstall web_proxy with RedHat os family' do
  			
  		let(:facts) { {:osfamily => 'RedHat', :operatingsystem => 'Centos', :path => '/root/bin'} }
  		let(:params) { {:install_file_name => 'web_proxy.bin',:install_file_location => '/root',:ensure => "uninstalled",:install_dependent_packages => "yes",} }

  		it do should contain_exec('uninstall_netapp_web').with(
          'command' => '"/opt/netapp/santricity_web_services_proxy/uninstall_web_services_proxy/uninstall_web_services_proxy" -i silent',
	        'onlyif'  => "test -e  \"/opt/netapp/santricity_web_services_proxy/uninstall_web_services_proxy\"  ",
	        'path'    => '/root/bin',
        ) end
  	end

  	context 'should install web_proxy with windows os family' do
  			
  		let(:facts) { {:osfamily => 'windows', :operatingsystem => 'windows'} }
  		let(:params) { {:install_file_name => 'web_proxy.exe',:install_file_location => 'C:',:ensure => "installed",:install_dependent_packages => "no",} }

  		it { should contain_class('netapp_e::web_proxy_params') }

	  	it do should contain_file('installation_file').with(
	        'ensure'  => 'file',
	        'path'    => 'C:/web_proxy.exe',
	        'replace' => 'no',
	        'mode'    => '0777',
	        'source'  => 'puppet:///modules/netapp_e/web_proxy.exe',
	    ) end

	  	it do should contain_exec('install_netapp_web').with(
          'command' => 'C:/web_proxy.exe -i silent',
	        'path'    => 'C:',
	        'cwd'     => 'C:',
	        'creates' => 'C:/Program Files/NetApp/SANtricity Web Services Proxy/uninstall_web_services_proxy',
        ) end

	  	it do should contain_service('NetAppWebServicesProxy').with(
            'require' => 'Exec[install_netapp_web]',
            'enable'  => 'true',
            'ensure'  => 'running'
        ) end
  	end

  	context 'should uninstall web_proxy with windows os family' do
  			
  		let(:facts) { {:osfamily => 'windows', :operatingsystem => 'windows', :path => 'C:/windows/bin'} }
  		let(:params) { {:install_file_name => 'web_proxy.exe',:install_file_location => 'C:',:ensure => "uninstalled",:install_dependent_packages => "no",} }

  		it do should contain_exec('uninstall_netapp_web').with(
            'command' => '"C:/Program Files/NetApp/SANtricity Web Services Proxy/uninstall_web_services_proxy/uninstall_web_services_proxy.exe" -i silent',
	        'onlyif'  => 'cmd /c if not exist   "C:/Program Files/NetApp/SANtricity Web Services Proxy/uninstall_web_services_proxy"  exit 1',
	        'path'    => 'C:/windows/bin',
        ) end
  	end

end