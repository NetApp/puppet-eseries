# netapp_e

The NetApp E-Series module manages E-Series storage arrays using Puppet Network Device.

## Requirements ##

* SANtricity Web Service is used as a proxy between puppet and storage array
* [Excon](https://github.com/excon/excon) - ruby http client 

## Usage ##

```puppet
node 'puppet.node.local' {

  #include class with to initialize default module parameters
  include netapp_e
  
  #OR comment above default block and uncomment below block to include parameterized class for Windows Agents
  #class{ 'netapp_e':
  #    owner			=> "administrator",
  #    group			=> "administrators",
  #	   mode				=> '0777',
  #    device_conf_dir	=> "C:\Program Files\Puppet Labs\Puppet\puppet",
  #}

  #OR comment above default block and uncomment below block to include parameterized class for SUSE/Solaris Agents
  #class{ 'netapp_e':
  #    owner => root,
  #    group => root,
  #    device_conf_dir => '/etc/puppet',
  #}
  
  #OR comment above default block and uncomment below block to include parameterized class for CentOS/Redhat
  #class{ 'netapp_e':
  #    owner => root,
  #    group => root,
  #}

  #The below block will install/uninstall NetApp SANtricity Web Services Proxy on Linux Agent Node
  class { 'netapp_e::web_proxy':
      ensure 	      			 => 'installed', #Possible value for ensure 'installed' or 'absent'
      install_file_name			 => 'webservice-01.20.7000.0005.bin', #Web Proxy Installation file kept in modules/netapp_e/files
      install_file_location		 => '/opt', #This folder must exist on Agent Node
	  install_dependent_packages => 'yes', #Only if 'LSB' is not already installed on linux
  }
  
  #OR
  #Comment above linux block and uncomment below block to install/uninstall NetApp SANtricity Web Services Proxy on Windows Agent Node
  #class { 'netapp_e::web_proxy':
  #    ensure						=> 'installed', #Possible value for ensure 'installed' or 'absent'
  #    install_file_name			=> 'webservice-01.20.3000.0005.exe', #Web Proxy Installation file kept in modules/netapp_e/files
  #    install_file_location		=> 'H:/setup', #This folder must exist on Agent Node
  #	   install_dependent_packages	=> 'no', #No for windows agents always as windows don't need any LSB(Linux Standard Base) packages
  #}

  # Host/Domain name/IP address where SANtricity Web Proxy is installed or needs to be installed
  $hostname = 'storage.device.local'
  $username = 'rw'
  $password = 'rw'
  
  #SANtricity web proxy puppet device configuration file name.
  $proxy_device_config_file = 'proxy_device_config'

  # The below block will create a puppet device configuration file on agent node which have connection details to SANtricity Web Proxy
  netapp_e::config { $proxy_device_config_file:
      username      => $username,
      password      => $password,
      url           => $hostname,
      port          => '8080',
      target        => "${netapp_e::device_conf_dir}/device/${proxy_device_config_file}.conf"
  }

  # Set up a cron job for running puppet device periodically for CentOS/Redhat Agent Nodes
  cron { "netappe-puppet-device-run":
      command 	   => "puppet device --deviceconfig ${netapp_e::device_conf_dir}/device/${proxy_device_config_file}.conf -d",
      minute  	   => fqdn_rand(60),
	  environment  => "PATH=${::path}:/opt/puppetlabs/puppet/bin"
  }
  # OR comment above block and uncomment below block to set up a cron job for running puppet device periodically for SUSE/Solaris Agent Nodes
  #cron { "netappe-puppet-device-run":
  #    command 	   => "puppet device --deviceconfig ${netapp_e::device_conf_dir}/device/${proxy_device_config_file}",
  #    minute  	   => fqdn_rand(60),
  #   environment  => "PATH=${::path}:/opt/puppet/bin"
  #}
  
  # OR comment above block and uncomment below block to set up a scheduled task for running puppet device periodically on Windows Agent Nodes
  #scheduled_task { 'netappe-puppet-device-run':
  #    ensure      => present,
  #    command     => 'C:/\"Program Files\"/\"Puppet Labs\"/Puppet/bin/puppet.bat',
  #    arguments   => "device --deviceconfig ${netapp_e::device_conf_dir}/device/${proxy_device_config_file}.conf -d",
  #    user        => 'Administrator',
  #    password    => 'password@123',
  #    enabled     => true,
  #    trigger     => {
  #        schedule   => daily,
  #        every      => 1,            # Specifies every other day. Defaults to 1 (every day).
  #        start_date => '2015-11-05', # Defaults to 'today'
  #        start_time => '18:12',      # Must be specified
  #  }
  #}

  # Get firmware upgrade version file from pupper server onto puppet agent machine
  # Use the below block while upgrading CFW or NVSRAM firmware
  $firmware_file = 'firmware_filename.dlp'
  file { $firmware_file:
      ensure    => file,
      path      => "/root/${firmware_file}", #agent machine path to download file from puppet server
      mode      => '0777',
      source    => "puppet:///modules/netapp_e/${firmware_file}", #Firmware .dlp file kept in modules/netapp_e/files
  }

}

###
# Configurations to be executed on NetApp Storage Arrays view SANtricity Web Proxy
# Node name must be same as proxy device configuration file name given in parameter $proxy_device_config_file.
# The proxy device configuration file will contain the host/domain name of SANtricity Web Proxy
###
node 'proxy_device_config' {

  $status = present
  $storage_system = 'second'

  netapp_e_storage_system {$storage_system:
      ensure      => $status,
      controllers => ['10.250.117.116', '10.250.117.117'],
      password    => 'Password_1234',
  }

  netapp_e_storage_system {'third':
      ensure      => $status,
      controllers => ['10.250.117.114', '10.250.117.115'],
  }

  # We need to wait before storage-system will be fully initialized. 	
  # We can use fact exported by the module: $::initialized_systems
  # and postpone operations involving storage-system resource to next puppet run.
  if $::initialized_systems and ($storage_system in $::initialized_systems) {

    # Volume group
    netapp_e_storage_pool {'raid5pool-second':
      ensure        => $status,
      storagesystem => $storage_system,
      raidlevel     => 'raid5',
      diskids       => [
        '010000005000CCA0577B11A00000000000000000',
        '010000005000CCA0577B13A40000000000000000',
        '010000005000CCA0577B58700000000000000000',
      ],
    }

    netapp_e_storage_pool {'raid5pool-third':
      ensure        => $status,
      storagesystem => 'third',
      raidlevel     => 'raid5',
      diskids       => [
        '010000005000CCA0577D11A00000000000000000',
        '010000005000CCA0577D13A40000000000000000',
        '010000005000CCA0577D58700000000000000000',
      ],
    }

    # Disk pool
    netapp_e_storage_pool {'disk-pool-1':
      ensure        => $status,
      storagesystem => $storage_system,
      raidlevel     => 'raidDiskPool',
      diskids       => [
        '010000005000CCA05763E8A80000000000000000',
        '010000005000CCA05764AEF00000000000000000',
        '010000005000CCA05767B06C0000000000000000',
        '010000005000CCA05763E8A80000000000000000',
        '010000005000CCA05764AEF00000000000000000',
        '010000005000CCA05767B06C0000000000000000',
        '010000005000CCA05763E8A80000000100000000',
        '010000005000CCA05764AEF00000000200000000',
        '010000005000CCA05767B06C0000000300000000',
        '010000005000CCA05764AEF00000000400000000',
        '010000005000CCA05767B06C0000000500000000',
      ],
    }

    # Standard volume
    netapp_e_volume {'volume-standard-second':
      ensure        => $status,
      storagesystem => $storage_system,
      size          => 1,
      storagepool   => 'raid5pool-second',
      sizeunit      => 'gb',
      segsize       => '512',
    }

    netapp_e_volume {'volume-standard-third':
      ensure        => $status,
      storagesystem => 'third',
      size          => 1,
      storagepool   => 'raid5pool-second',
      sizeunit      => 'gb',
      segsize       => '512',
    }

    # Thin volume
    netapp_e_volume {'new-thin-volume':
      ensure            => $status,
      storagesystem     => $storage_system,
      size              => 4,
      sizeunit          => 'gb',
      repositorysize    => 10,
      maxrepositorysize => 15,
      storagepool       => 'disk-pool-1',
      thin              => true
    }

    # Volume copy
    netapp_e_volume_copy {'new-copy-volume':
      ensure               => $status,
      storagesystem        => $storage_system,
      source               => 'volume-standard-second',
      target               => 'new-thin-volume',
      copypriority         => 'priority3',
      targetwriteprotected => false,
      disablesnapshot      => true
    }

    # Hosts and Host Groups
    netapp_e_host_group {'zone2':
      ensure        => $status,
      storagesystem => $storage_system,
    }

    $ports = [
      {
        type => 'iscsi',
        port => 'iqn.1998-05.com.windows:cd42b74121212',
        label => 'newone'
      }
    ]

    netapp_e_host {'linux-test':
      ensure        => $status,
      typeindex     => 9,
      storagesystem => $storage_system,
      groupid       => 'zone2',
      ports         => $ports,
    }

    # Lun map	
    netapp_e_map {'new-thin-volume':
      ensure        => $status,
      storagesystem => $storage_system,
      lun           => 11,
      source        => 'new-thin-volume',
      target        => 'zone2',
      type          => hostgroup
    }

    # Snapshot group
    netapp_e_snapshot_group {'new-snapshot-group':
      ensure         => $status,
      storagesystem  => $storage_system,
      storagepool    => 'disk-pool-1',
      volume         => 'new-thin-volume',
      repositorysize => 30,
      warnthreshold  => 75,
      policy         => 'purgepit',
      limit          => 7
    }

    # Async Mirror Group
    netapp_e_mirror_group {'new-mirror-group':
      ensure            => $status,
      primaryarray      => $storage_system,
      secondaryarray    => 'third',
      syncinterval      => 11,
      syncthreshold     => 16,
      recoverythreshold => 22,
      repothreshold     => 43,
    }

    netapp_e_mirror_members {'new-mirror-members':
      ensure          => $status,
      primaryvolume   => 'volume-standard-second',
      secondaryvolume => 'volume-standard-third',
      mirror          => 'new-mirror-group'
    }

    #Consistancy Group
    #Create
    netapp_e_consistency_group {'CG-GROUP-Create':
      ensure                    => $status,
      consistencygroup          => 'CG_GROUP1',
      storagesystem             => $storage_system,
      fullwarnthresholdpercent  => 75,
      autodeletethreshold       => 32,
      repositoryfullpolicy      => 'purgepit',
      rollbackpriority          => 'medium',
    }

    #Create
    netapp_e_consistency_group {'CG-GROUP-Create':
      ensure                    => $status,
      consistencygroup          => 'CG_GROUP2',
      storagesystem             => $storage_system,
    }

    #Update
    netapp_e_consistency_group {'CG-GROUP-Update':
      ensure                    => $status,
      consistencygroup          => 'CG_GROUP2',
      storagesystem             => $storage_system,
      fullwarnthresholdpercent  => 80,
      autodeletethreshold       => 30,
      repositoryfullpolicy      => 'purgepit',
      rollbackpriority          => 'medium',
    } 

    #Delete
    netapp_e_consistency_group {'CG-GROUP-Delete':
      ensure                    => absent,
      consistencygroup          => 'CG_GROUP1',
      storagesystem             => $storage_system,
    } 

    #Consistancy Group Member
    #Add Member
    netapp_e_consistency_members {'Add-Volume':
        ensure           => $status,
        volume           => 'Volume-1',
        storagesystem    => $storage_system,
        consistencygroup => 'CG-GROUP',
        repositorypool   => 'Disk_Pool_1',
        scanmedia        => true,
        validateparity   => true,
        repositorypercent => 10,
    }

    #Remove Member
    netapp_e_consistency_members {'Remove-Volume':
        ensure           => $status,
        volume           => 'Volume-1',
        storagesystem    => $storage_system,
        consistencygroup => 'CG-GROUP',
    } 

    $volumes = [{
                  repositorypool    => 'Disk_Pool_1',
                  volume            => 'Volume-1',
                  scanmedia         => true,
                  validateparity    => true,
                  repositorypercent => 10,
                },
                {
                  repositorypool    => 'Disk_Pool_1',
                  volume            => 'Volume-2',
                  scanmedia         => true,
                  validateparity    => true,
                  repositorypercent => 10,
                }]

    netapp_e_consistency_multiple_members{ 'ADD-BATCH-VOLUMES':
        volumes             => $volumes,
        storagesystem       => $storage_system,
        consistencygroup    => 'CG-GROUP',
    }

    #Consistancy Group Snapshots
    #Create Snapshot
    netapp_e_consistency_group_snapshot {'CG-GROUP-Snap1':
        ensure              => $status,
        consistencygroup    => 'CG-GROUP',
        storagesystem       => $storage_system,
    }
    
    #Remove Oldest Snapshot
    netapp_e_consistency_group_snapshot {'CG-GROUP-Snap1-Delete':
        ensure              => absent,
        consistencygroup    => 'CG-GROUP',
        storagesystem       => $storage_system,
    }

    #Rollback Consistency Group to an Older Snapshot
    netapp_e_consistency_group_rollback {'CG-555-Rollback':
        snapshotnumber      =>  53,
        consistencygroup    => 'CG-555',
        storagesystem       => $storage_system,
    }

    #Consistancy Group Snapshots Views
    #Create Snapshot View for all volumes in the snapshot
    netapp_e_consistency_group_snapshot_view {'CG-GROUP-View1':
        ensure              => $status,
        viewname            =>'CG-GROUP-View1',
        storagesystem       => $storage_system,
        consistencygroup    => 'CG-GROUP',
        snapshotnumber      => 74,
        viewtype            => 'bySnapshot',
        validateparity      => false,
    }

    #Create Snapshot View for a single volume in the snapshot
    netapp_e_consistency_group_snapshot_view {'CG-GROUP-View2':
        viewname            =>'CG-GROUP-View2',
        ensure              => $status,
        storagesystem       => $storage_system,
        consistencygroup    => 'CG-GROUP',
        snapshotnumber      => 74,
        viewtype            => 'byVolume',
        volume              => 'Test-Vol-1',
        validateparity      => false,
        repositorypool      => 'DiskPool1',
        scanmedia           => true,
        repositorypercent   => 75,
        accessmode          => 'readWrite',

    }

    #Consistancy Group Snapshots Views
    #Remove Snapshot View
    netapp_e_consistency_group_snapshot_view {'CG-GROUP-View1-Delete':
        viewname            =>'CG-GROUP-View1',
        ensure              => absent,
        storagesystem       => $storage_system,
        consistencygroup    => 'CG-GROUP',
    }

    $firmware_file = 'N5468-820834-DB5.dlp'

    #Upload firmware file
    netapp_e_firmware_file{ 'upload_firmware_file':
        filename            => $firmware_file,
        folderlocation      => 'C://upgrade', #agent machine path where firmware file downloaded from puppet server
        ensure              => $status, 
        validate_file       => true,
    }

    #Delete firmware file
    netapp_e_firmware_file{ 'delete_firmware_file':
        ensure              => 'absent', 
        filename            => $firmware_file,
    }

    #Upgrade nvsram firmware with compatibility check skipping and mel check and waiting for completion until execution of next resource
    netapp_e_firmware_upgrade{ 'upgrade_firmware' :
        ensure              => 'upgraded',
        storagesystem       => $storage_system,
        filename            => $firmware_file,
        firmwaretype        => 'nvsramfile',
        melcheck            => true,
        compatibilitycheck  => true,
        releasedbuildonly   => true,
        waitforcompletion   => true,
    }

    # Upgrade cfw firmware skipping mel check and without compatibility check and not waiting for completion of execution of the resource
    netapp_e_firmware_upgrade{ 'upgrade_firmware' :
        ensure              => 'upgraded',
        storagesystem       => $storage_system,
        filename            => $firmware_file,
        firmwaretype        => 'cfwfile',
        melcheck            => false,
        compatibilitycheck  => false,
        waitforcompletion   => false,
    }

    #Stage nvsram firmware with compatibility check skipping and mel check and waiting for completion until execution of next resource
    netapp_e_firmware_upgrade{ 'stage_firmware' :
        ensure              => 'staged',
        storagesystem       => $storage_system,
        filename            => $firmware_file,
        firmwaretype        => 'nvsramfile',
        melcheck            => true,
        compatibilitycheck  => true,
        releasedbuildonly   => true,
        waitforcompletion   => true,
    }

    #Stage cfw firmware skipping mel check and without compatibility check and not waiting for completion of execution of the resource
    netapp_e_firmware_upgrade{ 'stage_firmware' :
        ensure              => 'staged',
        storagesystem       => $storage_system,
        filename            => $firmware_file,
        firmwaretype        => 'cfwfile',
        melcheck            => false,
        compatibilitycheck  => false,
        waitforcompletion   => false,
    }

    #Activate nvsram firmware skipping mel check and waiting for completion until execution of next resource
    netapp_e_firmware_upgrade{ 'activate_firmware' :
        ensure              => 'activated',
        storagesystem       => $storage_system,
        firmwaretype        => 'nvsramfile',
        melcheck            => false,
        waitforcompletion   => true,
    }

    #Activate cfw firmware with mel check and without waiting for completion of execution of this resource
    netapp_e_firmware_upgrade{ 'activate_firmware' :
        ensure              => 'activated',
        storagesystem       => $storage_system,
        firmwaretype        => 'cfwfile',
        melcheck            => true,
        waitforcompletion   => false,
    }

    #Upgrade NetApp SANtricity Web Services Proxy
    #Download and install new version
    netapp_e_web_proxy_upgrade{ 'upgrade_web_proxy':
        ensure  => 'upgraded',
        force   => 'true',
    }

    #Stage NetApp SANtricity Web Services Proxy
    #Stage new version
    netapp_e_web_proxy_upgrade{ 'stage_web_proxy':
        ensure  => 'staged',
        force   => 'true',
    }

    #Activate staged version of Santricity Web Proxy Server
    netapp_e_web_proxy_upgrade{ 'activate_web_proxy':
        ensure  => 'activated',
    }

    $diskIds = [ "010000005001E8200002D1A80000000000000000",
                 "010000005001E8200002D20C0000000000000000"]
    #Flash Cache
    #Create Flash Cache
    netapp_e_flash_cache {'createBlock':
        ensure                => created,
        cachename             => 'SSD_1',
        storagesystem         => $storage_system,
        diskids               =>  $diskIds,
        enableexistingvolumes =>  false,
    }

    #Suspend Flash Cache
    netapp_e_flash_cache {'suspendBlock':
        ensure               => suspended,
        cachename            => 'SSD_1',
        storagesystem        => $storage_system,
        ignorestate          => false,
    }

    #Resume Flash Cache
    netapp_e_flash_cache {'ResumeBlock':
        ensure               => resumed,
        cachename            => 'SSD_1',
        storagesystem        => $storage_system,
        ignorestate          => true,
    }

    #Update Flash Cache
    netapp_e_flash_cache {'updateBlock':
        ensure              => updated,
        cachename           => 'SSD_1',
        storagesystem       => $storage_system,
        newname             => 'SSD_12',
        configtype          => 'database',
    }

    #Delete Flash Cache
    netapp_e_flash_cache {'deleteBlock':
        ensure              => deleted,
        cachename           => 'SSD_1',
        storagesystem       => $storage_system,
    }
  
    #Flash Cache Drives
    #Add flash Cache drives
    netapp_e_flash_cache_drives {'addFlashCacheDrives':
        ensure              => present,
        cachename           => 'SSD_1',
        storagesystem       => $storage_system,
        diskids             =>  $diskIds,
    }

    #Remove flash Cache drives
    netapp_e_flash_cache_drives {'removeFlashCacheDrives':
        ensure              => absent,
        cachename           => 'SSD_1',
        storagesystem       => $storage_system,
        diskids             =>  $diskIds,
    }

  } else {
    notice("Wait to initialize storage-system: ${storage_system}")
  }

  # Dependencies chains
  if $status == present {
    Netapp_e_storage_system <| |> -> Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> ->
    Netapp_e_volume_copy <| |> -> Netapp_e_snapshot_group <| |> -> Netapp_e_host_group <| |> -> 
    Netapp_e_host <| |> -> Netapp_e_map <| |> -> Netapp_e_mirror_group <| |> -> Netapp_e_mirror_members <| |> -> 
	  Netapp_e_consistency_group <| |> -> Netapp_e_consistency_members <| |> -> Netapp_e_consistency_multiple_members <| |> ->
	  Netapp_e_consistency_group_snapshot <| |> -> Netapp_e_consistency_group_rollback <| |> -> 
    Netapp_e_consistency_group_snapshot_view <| |>-> Netapp_e_flash_cache <||>-> Netapp_e_flash_cache_drives <||>
  }
  elsif $status == absent {
    Netapp_e_flash_cache_drives <||>-> Netapp_e_flash_cache <||>->
    Netapp_e_consistency_group_snapshot_view <| |> -> Netapp_e_consistency_group_rollback <| |> -> 
    Netapp_e_consistency_group_snapshot <| |> -> Netapp_e_consistency_multiple_members <| |> -> Netapp_e_consistency_members <| |> -> Netapp_e_consistency_group <| |> -> Netapp_e_mirror_members <| |> -> Netapp_e_mirror_group <| |> -> Netapp_e_map <| |> ->  Netapp_e_host <| |> -> Netapp_e_host_group <| |> -> Netapp_e_snapshot_group <| |> -> Netapp_e_volume_copy <| |> ->
    Netapp_e_volume <| |> -> Netapp_e_storage_pool <| |> -> Netapp_e_storage_system <| |> 
  }
  
}
```
## Reference ##

netapp_e::web_proxy_config
-----------
SANtricity Web Services Proxy installation

### Attributes ###

* `ensure` Ensure that netappweb_service will be installed or absent
* `install_file_name` Name of the installation file inside the folder named files in the module
* `install_file_location` Location where the installation file will be copied
* `install_dependent_packages` Enable or disable installation of dependent packages


netapp_e_storage_system
-----------
Manage Netapp E series storage system creation, modification and deletion.

### Attributes ###

* `name` Storage System ID.
* `password` Storage system password.
* `controllers` (array of string) Controllers IP addresses or host names.
* `meta_tags` (array of hashes) Optional meta tags to associate to this storage system.

netapp_e_storage_pool
-----------
Manage Netapp E series storage disk pool

### Attributes ###

* `name` The user-label to assign to the new storage pool.
* `diskids` Array of the identifiers of the disk drives to use for creating the storage pool.
* `storagesystem` Storage system ID.
* `raidlevel` The RAID configuration for the new storage pool. Possible values: 'raidUnsupported', 'raidAll', 'raid0', 'raid1', 'raid3', 'raid5', 'raid6', 'raidDiskPool', '__UNDEFINED'
* `erasedrives` (boolean, default false) Security-enabled drives that were previously part of a secured storage pool must be erased before they can be re-used. Enable to automatically erase such drives.

netapp_e_volume
-----------
Manage Netapp E series volume

### Attributes ###

* `name` The user-label to assign to the new volume.
* `thin` (boolean, default false) If true thin volume will be created.
* `storagesystem` Storage system ID.
* `storagepool` Name of storage poll from which the volume will be allocated.
* `sizeunit` Unit for size. Possible values: 'bytes', 'b', 'kb', 'mb', 'gb', 'tb', 'pb', 'eb', 'zb', 'yb'
* `size` Number of units to make the volume.
* `segsize` (only standard volume) The segment size of the volume.
* `dataassurance` (boolean) If true data assurance enabled.
* `defaultmapping` (boolean, thin volume) Create the default volume mapping.
* `owningcontrollerid` (thin volume) Set the initial owning controller.
* `repositorysize` (thin volume) Number of units to make the repository volume, which is the backing for the thin volume.
* `maxrepositorysize` (thin volume) Maximum size to which the thin volume repository can grow. Must be between 4GB & 256GB.
* `growthalertthreshold` (thin volume) The repository utilization warning threshold (in percent).
* `expansionpolicy` (thin volume) Thin Volume expansion policy. If automatic, the thin volume will be expanded automatically when capacity is exceeded, if manual, the volume must be expanded manually. Possible values: 'unknown', 'manual', 'automatic', '__UNDEFINED'
* `cachereadahead` (thin volume) If true automatic cache read-ahead enabled

netapp_e_snapshot_group
-----------
Manage Netapp E series snapshot groups

### Attributes ###

* `name`The name of the new snapshot group.
* `storagesystem` Storage system ID.
* `storagepool` The name of the storage pool to allocate the repository volume.
* `volume` Then name of the volume for the new snapshot group
* `repositorysize` The percent size of the repository in relation to the size of the base volume.
* `warnthreshold` The repository utilization warning threshold, as a percentage of the repository volume capacity.
* `limit` The automatic deletion indicator. If non-zero, the oldest snapshot image will be automatically deleted when creating a new snapshot image to keep the total number of snapshot images limited to the number specified.
* `policy` The behavior on when the data repository becomes full. Possible values: 'unknown', 'failbasewrites', 'purgepit', '__UNDEFINED'

netapp_e_snapshot_image
-----------
Manage Netapp E series snapshot image

This type require `:schedule` meta-parameter to be set.

### Attributes ###

* `name` The name of the puppet resource.
* `storagesystem` Storage system ID.
* `group` Name of snapshot group.

```puppet
schedule { 'everyday':
  period   => daily,
  repeat   => 1,
}

netapp_e_snapshot_image {'daily-snapshot':
  group         => 'NewSnapshotGroup',
  storagesystem => 'sys_id',
  schedule      => 'everyday',
  require       => Netapp_e_snapshot_group['NewSnapshotGroup']
}
```

netapp_e_snapshot_volume
-----------
Manage Netapp E series snapshot volume

### Attributes ###

* `name` The user-label to assign to the new snapshot volume.
* `imageid` The identifier of the snapshot image used to create the new snapshot volume.
* `storagesystem` Storage system ID.
* `storagepool` Name of storage poll from which the volume will be allocated.
* `fullthreshold` The repository utilization warning threshold percentage.
* `viewmode` The snapshot volume access mode. Possible values: 'modeUnknown', 'readWrite', 'readOnly', '__UNDEFINED'
* `repositorysize` The size of the view in relation to the size of the base volume.

```puppet
netapp_e_snapshot_volume {'NewSnapshotVol':
  storagesystem  => 'sys_id',
  imageid        => '34000000600A098000607399006302C054DDC033',
  storagepool    => 'raid5pool',
  viewmode       => 'readWrite',
  repositorysize => 10,
  fullthreshold  => 14,
  require        => Netapp_e_storage_pool['raid5pool']
}
```

netapp_e_volume_copy
-----------
Manage Netapp E series volume copy

### Attributes ###

* `name` The user-label to assign to the new volume copy.
* `storagesystem` Storage system ID.
* `source` Name of the source volume for the copy job.
* `target` Name of the target volume for the copy job.
* `copypriority` The priority of the copy job (0 is the lowest priority, 4 is the highest priority). Possible values: 'priority0', 'priority1', 'priority2', 'priority3', 'priority4', '__UNDEFINED'
* `targetwriteprotected` (boolean) Specifies whether to block write I/O to the target volume while the copy job exists.
* `disablesnapshot` (boolean) Will disable the target snapshot after the copy completes and purge the associated group when the copy pair is deleted.

netapp_e_host
-----------
Manage Netapp E series hosts

### Attributes ###

* `name` The user-label to assign to the new host.
* `storagesystem` Storage system ID.
* `typeindex` HostType index.
* `groupid` Name of host group where host belongs.
* `ports` (array of hashes) Host addresses.

netapp_e_host_group
-----------
Manage Netapp E series host group

### Attributes ###

* `name` The user-label to assign to the new host.
* `storagesystem` Storage system ID.
* `hosts` (array of string) IDs of hosts

netapp_e_map
-----------
Manage Netapp E series volume mappings

### Attributes ###

* `name` The user-label to assign to the new volume mapping.
* `storagesystem` Storage system ID.
* `source` Name of the source volume.
* `target` The host group or a host for the volume mapping.
* `type` Type of target. Possible values: host, hostgroup
* `lun` The LUN for the volume mapping.

netapp_e_mirror_group
-----------
Manage Netapp E series mirror group

### Attributes ###

* `name` The user-label to assign to the new mirror group.
* `primaryarray` The id of the secondary array.
* `secondaryarray` The id of the secondary array.
* `interfacetype` The intended protocol to use if both Fibre and iSCSI are available. Possible values: 'fibre', 'iscsi', 'fibreAndIscsi', 'none'
* `syncinterval` Sync interval (minutes).
* `recoverythreshold` Recovery point warning threshold (minutes).
* `repothreshold` Repository utilization warning threshold.
* `syncthreshold` Sync warning threshold (minutes).

netapp_e_mirror_members
-----------
Manage Netapp E series mirror group members

### Attributes ###

* `name` Puppet resource name.
* `primaryvolume` Name of primary volume.
* `secondaryvolume` Name of secondary volume.
* `mirror` Name of mirror group.
* `capacity` Percentage of the capacity of the primary volume to use for the repository capacity.
* `scanmedia` (boolean)
* `validateparity` (boolean) Validate repository parity.

netapp_e_network_interface
-----------
Manage Netapp E series management network configuration

### Attributes ###

* `macaddr` An ASCII string representation of the globally-unique 48-bit MAC address assigned to the Ethernet interface.
* `storagesystem` Storage system ID.
* `ipv4` (boolean) True if ipv4 is to be enabled for this interface.
* `ipv4address` The ipv4 address for the interface. Required for static configuration.
* `ipv4mask` The ipv4 subnet mask for the interface. Required for static configuration.
* `ipv4gateway` Manually specify the address of the gateway.
* `ipv4config` Setting that determines how the ipv4 address is configured. Required if ipv4 is enabled. Possible values: 'configDhcp', 'configStatic', '__UNDEFINED'
* `ipv6` (boolean) True if ipv6 is to be enabled for this interface.
* `ipv6address` The ipv6 local address for the interface.
* `ipv6config` The method by which the ipv6 address information is configured for the interface. Possible values: 'configStatic', 'configStateless', '__UNDEFINED'
* `ipv6gateway` Manually specify the address of the gateway.
* `ipv6routableaddr` 
* `remoteaccess` (boolean) If set to true, the controller is enabled for establishment of a remote access session. Depending on the controller platform, the method for remote access could be rlogin or telnet.
* `speed` The configured speed setting for the Ethernet interface. Possible values: 'speedNone', 'speedAutoNegotiated', 'speed10MbitHalfDuplex', 'speed10MbitFullDuplex', 'speed100MbitHalfDuplex', 'speed100MbitFullDuplex', 'speed1000MbitHalfDuplex', 'speed1000MbitFullDuplex', '__UNDEFINED'

```puppet
netapp_e_network_interface {"00A098607387":
  storagesystem => 'sys_id',
  ipv4          => true,
  ipv4config    => 'configStatic',
  ipv4address   => '10.250.117.117',
  ipv4gateway   => '10.250.116.1',
  ipv4mask      => '255.255.252.0',
  remoteaccess  => true,
}
```

netapp_e_password
-----------
Manage Netapp E series storage array password

### Attributes ###

* `storagesystem` Storage system ID.
* `current` Current admin password
* `new` New password.
* `admin` (boolean) If this is true, this will set the admin password, if false, it sets the RO password.
* `force` (boolean) If true it will always try change password, even if already set. We can not check if passwords match.

```puppet
netapp_e_password {'sys_id':
  current => '',
  new     => 'new_password',
  admin   => true,
  force   => false,
}
```
netapp_e_consistency_group
-----------
Manage Netapp E series consistency groups

### Attributes ###

* `consistencygroup` The user-label to assign to the new consistency group.
* `storagesystem` Group storage system id.
* `fullwarnthresholdpercent` The full warning threshold percent.
* `autodeletethreshold` The auto-delete threshold. Automatically delete snapshots after this many..
* `repositoryfullpolicy` The repository full policy. Possible Values ('purgepit', 'failbasewrites').
* `rollbackpriority` Roll-back priority. Possible Values ('highest', 'high', 'medium', 'low', 'lowest')

netapp_e_consistency_members
-----------
Manage Netapp E series consistency group members

### Attributes ###

* `volume` Member Volume name.
* `storagesystem` Group storage system id.
* `consistencygroup` Consistency Group Name.
* `repositorypool` The repository volume pool.
* `scanmedia` (boolean)
* `validateparity` (boolean) Validate repository parity.
* `repositorypercent` Repository Percent
* `retainrepositories` (boolean) Delete all repositories assosiated with the member volume. (Use when want to remove member volume)

netapp_e_consistency_multiple_members
-----------
Manage Netapp E series consistency group members

### Attributes ###

* `name` The user-label to assign for volume batch insert.
* `storagesystem` Group storage system id.
* `consistencygroup` Consistency Group Name.
* `volumes` (array of hashes) Volumes details.

### Attributes for volumes ###

* `volume` Member Volume name.
* `repositorypool` The repository volume pool.
* `scanmedia` (boolean)
* `validateparity` (boolean) Validate repository parity.
* `repositorypercent` Repository Percent

netapp_e_consistency_group_snapshot
-----------
Manage Netapp E series consistency group snapshots

### Attributes ###

* `consistencygroup` The user-label to assign to the new consistency group.
* `storagesystem` Group storage system id.


netapp_e_consistency_group_rollback
-----------
Manage Netapp E series consistency group rollbacks

### Attributes ###

* `snapshotnumber` The sequence number of snapshot to which the Consistency Group needs to be roll backed.
* `storagesystem` Group storage system id.
* `consistencygroup` Consistency Group Name.

netapp_e_consistency_group_snapshot_view
-----------
Manage Netapp E series consistency group snapshot views

### Attributes ###

* `viewname` The user-label to assign for volume batch insert.
* `storagesystem` Group storage system id.
* `consistencygroup` Consistency Group Name.
* `snapshotnumber` The sequence number of snapshot to which the Consistency Group needs to be roll backed.
* `viewtype` Value 'byVolume' ensures that the view should be created only for the mentioned volume from the consistency group snapshot. Value 'bySnapshot' ensures that views for all the volumes in consistency group snapshot are created
* `volume` Name of the volume from snapshot whose view needs to be created
* `scanmedia` (boolean)
* `validateparity` (boolean) Validate repository parity.
* `repositorypercent` The repository utilization warning threshold percentage.
* `accessmode` The view access mode. Possible values: 'readWrite', 'readOnly'
* `repositorypool` The name of the Storage Pool in which the view should be created.


netapp_e_firmware_file
-----------
Manage Netapp E series firmware cwf file for upload and delete on server

### Attributes ###

* `filename` Name of NVSRAM or Controller Firmware file (cwfFile/nvsramFile) name.
* `folderlocation` Folder Location of NVSRAM or Controller Firmware file from where it is to be uploaded.
* `validate_file` Check if the Firmware file is valid or not.


netapp_e_firmware_upgrade
------------
Manage Netapp E series firmware upgrade operation

### Attributes ###

* `filename` Name of NVSRAM or Controller Firmware file name.
* `firmwaretype` Possible values('cfwfile','nvsramfile'). 'cfwfile' will upgrade Controller firmware. 'nvsramfile' will upgrade NVSRAM firmware.
* `storagesystem` Group storage system id.
* `melcheck` If it is true and any issues found in mel check, firmware would not be upgraded. If it is false, the issues will be ignored and firmware will be upgraded.
* `compatibilitycheck` True will check the compatibility of uploaded firmware version with the storage array. False will not perform the check. Firmware will not be upgraded if check is enabled and compatibility fails.
* `releasedbuildonly` Only consider released firmware builds as valid Controller Firmware files for checking the compatibility.
* `waitforcompletion` true will wait for upgrade process to complete successfully. false will request to start the upgrade process and would not monitor success.
* `ensure` Possible values('upgraded','staged','activated')


netapp_e_web_proxy_upgrade
-----------
Manage Netapp E series SANtricity Web Services Proxy upgrade operation

### Attributes ###

* `name` Name of netapp_e_web_proxy_upgrade manifest block
* `ensure` Possible values('upgraded','staged','activated')
* `force` String value.

netapp_e_flash_cache
-----------
Manage Netapp E series SANtricity Web Services Flash Cache operation

### Attributes ###

* `name` Name of netapp_e_flash_cache manifest block.
* `cachename` Name of flash cache.
* `storagesystem` Storage system ID.
* `ensure` Possible values('created','suspended','resumed','updated','deleted').
* `diskids` Array of disk drive ids.
* `enableexistingvolumes` To enable existing volumes or not. Possible values('true','false').
* `newname` New name of flash cache.
* `configtype` Config type of flash cache. Possible values('database','multimedia','filesystem').
* `ignorestate` Possible values('true','false')

netapp_e_flash_cache_drives
-----------
Manage Netapp E series SANtricity Web Services Flash Cache Drives operation

### Attributes ###

* `name` Name of netapp_e_flash_cache manifest block.
* `cachename` Name of flash cache.
* `storagesystem` Storage system ID.
* `ensure` Possible values('present','absent').
* `diskids` Array of disk drive ids.


## Limitations ##

This module is tested against both [Open Source Puppet][] and [Puppet Enterprise][] on:

- CentOS 7
- Windows
- RedHat

This module also provides functions for other distributions and operating systems, such as Debian, SUSE, and Solaris, but is not formally tested on them and are subject to regressions.

- NetApp SANtricity Web Services Proxy version 1.3 supported.


## Contributing ##

Before creating pull request, run the tests and ensure that all Rspec pass.
You can also check acceptance test which can be found in [acceptancetests directory](acceptancetests/README.md)


## Authors & Contributors ##

* Janet Blagg <Janet.Blagg@netapp.com>
* Matt Tangvald <Matt.Tangvald@netapp.com>
* Frank Poole <Frank.Poole@netapp.com>
