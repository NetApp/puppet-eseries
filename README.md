# puppet-eseries

The NetApp E-Series module manages E-Series storage arrays using Puppet Network Device.

## Requirements ##

* SANtricity Web Service is used as a proxy between puppet and storage array
* [Excon](https://github.com/excon/excon) - ruby http client 

## Usage ##

```puppet
node 'puppet.node.local' {
  include netapp_e

  # This will prepare puppet device configuration on node which have
  # connection to SANtricity Web Proxy

  $hostname = 'netapp.local'
  netapp_e::config { $hostname:
    username => $username,
    password => $password,
    url      => $hostname,
    port     => '8080',
    target   => "${::settings::confdir}/device/${hostname}"
  }

  # Set up a cron job for running puppet device periodically
  cron { "netappe-puppet-device-run":
    command => "puppet device --deviceconfig ${::settings::confdir}/device/${hostname}",
    minute  => fqdn_rand(60),
  }
}

node 'netapp.local' {

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


  } else {
    notice("Wait to initialize storage-system: ${storage_system}")
  }

  # Dependencies chains
  if $status == present {
    Netapp_e_storage_system <| |> -> Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> ->
    Netapp_e_volume_copy <| |> -> Netapp_e_snapshot_group <| |> -> Netapp_e_host_group <| |> -> 
    Netapp_e_host <| |> -> Netapp_e_map <| |> -> Netapp_e_mirror_group <| |> -> Netapp_e_mirror_members <| |>
  }
  elsif $status == absent {
    Netapp_e_mirror_members <| |> -> Netapp_e_mirror_group <| |> -> Netapp_e_map <| |> ->  Netapp_e_host <| |> ->
    Netapp_e_host_group <| |> -> Netapp_e_snapshot_group <| |> -> Netapp_e_volume_copy <| |> ->
    Netapp_e_volume <| |> -> Netapp_e_storage_pool <| |> -> Netapp_e_storage_system <| |>
  }
}
```
## Reference ##

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

## Contributing ##

Before creating pull request, run the tests and ensure that all Rspec pass.
You can also check acceptance test which can be found in [acceptancetests directory](acceptancetests/README.md)

## Authors & Contributors ##

* Michał Skalski <mskalski@mirantis.com>
* Andrzej Skupień <askupien@mirantis.com>
* Denys Kravchenko <dkravchenko@mirantis.com>
