#!/usr/bin/python
# -*- coding: utf-8 -*-

import unittest2
from netapp_restlibs import generic_delete, generic_post, generic_get, array_controller
import os
import sh
import time
import re
import subprocess
import netapp_config as configuration
import datetime
import logging
import random

import pprint

class MyTestSuite(unittest2.TestCase):

    cookie = None
    http_pool = None
    url = None

    log = None
    ch = None

    output = None
    returncode = None

    bck_manifest_name = None
    manifest_path = None

    first_system_id = None
    first_system_ip1 = None
    first_system_ip2 = None
    first_system_pass = None
    first_system_test_pass = None
    first_system_test_ip = None

########################################################################################################################

    # IMPORTANT - one line for one option!!!

    manifest_frame = 'node "netapp.local" {{\n {inner_sections}\n }}\n'

    manifest_storage_system_section = \
'''
 netapp_e_storage_system {{"{system_id}":
      controllers => ["{system_ip1}","{system_ip2}"],
      password    => "{system_pass}",
      ensure      => {ensure},
    }}

    notify {{'{signature}':}}

'''

    manifest_storage_password_section = \
'''
       netapp_e_password {{"{system_id}":

         current => "{current_password}",
         new     => "{new_password}",
         admin   => {admin},
         force   => {force},

       }}
'''

    manifest_storage_interface_section = \
'''
netapp_e_network_interface {{"{macAddr}":
            storagesystem => "{system_id}",
            ipv4          => {ipv4},
            ipv4config    => "{ipv4config}",
            ipv4address   => "{ipv4address}",
            ipv4gateway   => "{ipv4gateway}",
            ipv4mask      => "{ipv4mask}",
            remoteaccess  => {remoteaccess},
         }}
'''

    # IMPORTANT - all 'disksid' in one line
    manifest_storage_pool_section = \
'''
  netapp_e_storage_pool {{'{pool_id}':
      ensure        => {ensure},
      storagesystem => "{system_id}",
      raidlevel     => '{raidlevel}',
      diskids       => {diskids},
    }}
'''

    manifest_storage_volume_section = \
'''
    netapp_e_volume {{'{volume_id}':
      require =>  Netapp_e_storage_pool['{pool_id}'],
      ensure        => {ensure},
      storagesystem => "{system_id}",
      size          => {size},
      storagepool   => '{pool_id}',
      sizeunit      => '{sizeunit}',
      segsize       => '{segsize}',
      thin          => {thin},
    }}
'''


########################################################################################################################

    @classmethod
    def switch_to_custom_manifest(cls, manifest_body):
        '''
        Helper to overwrite original manifest by custom manifest
        :param manifest_body:
        :return: None
        '''

        with open("/var/tmp/netapp_test_suite_tmp_site.pp", 'w') as temp_site_pp:
            temp_site_pp.write(manifest_body)

        if os.geteuid() != 0:
            sh.sudo('/bin/mv', '/var/tmp/netapp_test_suite_tmp_site.pp', cls.manifest_path + "/site.pp")
            sh.sudo('/bin/chmod', '664', cls.manifest_path + "/site.pp")
        else:
            sh.mv('/var/tmp/netapp_test_suite_tmp_site.pp', cls.manifest_path + "/site.pp")
            sh.chmod('664', cls.manifest_path + "/site.pp")

        # Show how looks like site.pp for now
        cls.log.debug("How looks site.pp for now (by 'cat {0}'):".format(cls.manifest_path + "/site.pp"))
        cls.log.debug(sh.cat(cls.manifest_path + "/site.pp"))

########################################################################################################################

    @classmethod
    def get_system_list(cls):
        objectBundle = generic_get('storage-systems')
        system_list = [s['id'] for s in objectBundle]
        return system_list

########################################################################################################################

    @classmethod
    def parse_multiline(cls, string):
        retval = ''
        for char in string:
            retval += char if not char == '\n' else ''
            if char == '\n':
                yield retval
                retval = ''
        if retval:
            yield retval
        return

########################################################################################################################

    @classmethod
    def output_errors_has_not(cls, pattern):

        for i in cls.parse_multiline(cls.output):
            if i.find('Error')>-1:
                if i.find(pattern)>-1:
                    cls.log.debug("Line from command output contains {pattern}:\n>>>{line}\n".format(pattern=pattern, line=i))
                    return False

        return True

########################################################################################################################

    @classmethod
    def output_errors_has(cls, pattern):
        # TODO Make return all lines not one
        result = False
        for i in cls.parse_multiline(cls.output):
            if i.find('Error')>-1:
                if i.find(pattern)>-1:
                    cls.log.debug("Line from command output contains {pattern}:\n>>>{line}\n".format(pattern=pattern, line=i))
                    result=True
        return result

########################################################################################################################

    @classmethod
    def run_puppet_device(cls, verbose=False):
        '''
        Helper to run puppet device by subprocess
        '''

        cls.log.debug("Delaying for working out puppet device issue...")
        time.sleep(15)
        cls.log.debug("Running shell command 'puppet device' by subprocess...")

        #return subprocess.check_output(['puppet device --debug --user root', '-1'], shell=True)
        child  = subprocess.Popen(['puppet','device','--debug','--user','root', ],
                                  stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT)
        cls.output = child.communicate()[0]
        cls.returncode = child.returncode

        if verbose:
            cls.log.debug('Output from puppet command:\n {output}\nReturn code: {returncode}\n'.format(output=cls.output,
                                                                                                       returncode=cls.returncode))

        # TODO What if we want to see not only systems but their entities????
        return cls.get_system_list()

########################################################################################################################

    @classmethod
    def rid_all_BANANAs(cls):

        for i in cls.get_system_list():
            if re.match(r'^BANANA[0-9]?_',i):
                cls.log.debug("Delete '{system_id}' system by REST ...".format(system_id=i))
                generic_delete('storage-system',array_id=i)

        # TODO For each BANANA system rid BANANA objects :)

        return

########################################################################################################################

    @classmethod
    def rid_system(cls, system_id):
        if cls.get_system_list():
            cls.log.debug("Delete '{system_id}' system by REST ...".format(system_id=system_id))
            try:
                generic_delete('storage-system',array_id=system_id)
            except:
                pass
        return

########################################################################################################################

    @classmethod
    def restore_first_system_by_REST(cls):

        if cls.first_system_id not in cls.get_system_list():
            data = {"id": cls.first_system_id,
                    "controllerAddresses": [cls.first_system_ip1, cls.first_system_ip1],
                    "password": cls.first_system_pass}
            first_system = generic_post('storage-systems', data)

        return

########################################################################################################################

    @classmethod
    def remove_line_from_multiline_regexp(cls, multiline, pattern):
        result = ''
        for l in cls.parse_multiline(multiline):
            if not re.search(pattern,l):
                result = result + l + '\n'
        return result

########################################################################################################################

    @classmethod
    def insert_line_to_multiline_regexp(cls, multiline, pattern, line):
        result = ''
        flag = True
        for l in cls.parse_multiline(multiline):
            result = result + l + '\n'
            if re.search(pattern, l) and flag:
                result = result + line + '\n'
                flag = False
        return result

########################################################################################################################

    # Get ip by REST
    @classmethod
    def get_ips_by_REST(cls, system_id):

        raw_ethernet_interfaces_list = generic_get('ethernet-interfaces', array_id=system_id)
        actual_ips = [i['ipv4Address'] for i in raw_ethernet_interfaces_list
                          if i['linkStatus'].strip() == 'up' and i['ipv4Enabled']]
        return actual_ips

########################################################################################################################

    # Construct dictionary for manifest section of first system
    @classmethod
    def construct_dict_for_first_system(cls, signature='BANANA_{0}', rand_hash=hex(random.getrandbits(24))[2:-1]):
        dict={}
        dict['system_id'] = cls.first_system_id
        dict['system_ip1'] = cls.first_system_ip1
        dict['system_ip2'] = cls.first_system_ip2
        dict['ensure'] = 'present'
        dict['system_pass']=cls.first_system_pass
        dict['signature']=signature.format(rand_hash)

        return dict

########################################################################################################################

    @classmethod
    def get_free_disk(cls, system_id, except_disks=(), number=1):
        disks=[]
        for i in generic_get('drives', array_id=system_id):
            if re.match('^0*$', i['currentVolumeGroupRef']):
                if i['id'] not in except_disks:
                    disks.append(str(i['id'].encode('utf-8').decode('ascii', 'ignore')))
            if len(disks) == number:
                break

        if len(disks) < number:
            raise RuntimeError('RUNTIME ERROR - THERE ARE NO TWO FREE DISKS ON STORAGE!!!')

        return disks

########################################################################################################################
    @classmethod
    def remove_BANANA_objects(cls, system_id):

        for volume in generic_get('volumes', array_id=system_id):
            if re.search('BANANA_VOLUME', volume['label']):
                cls.log.debug("DELETE VOLUME '{0}'!".format(volume['label']))
                generic_delete('volume', id=volume['id'], array_id=system_id)

        for thin_volume in generic_get('thin_volumes', array_id=system_id):
            if re.search('BANANA_VOLUME', thin_volume['label']):
                cls.log.debug("DELETE THIN VOLUME '{0}'!".format(thin_volume['label']))
                generic_delete('thin_volume', id=thin_volume['id'], array_id=system_id)

        for pool in generic_get('pools', array_id=system_id):
            if re.search('BANANA_POOL', pool['label']):
                cls.log.debug("DELETE POOL '{0}'!".format(pool['label']))
                generic_delete('pool', id=pool['id'], array_id=system_id)

        return
########################################################################################################################

    @classmethod
    def get_random_mac(cls):
        random_mac = [0x00, 0x24, 0x81,
                      random.randint(0x00, 0x7f),
                      random.randint(0x00, 0xff),
                      random.randint(0x00, 0xff) ]

        return ''.join(map(lambda x: "%02x" % x, random_mac))

########################################################################################################################

    @classmethod
    def setUpClass(cls):

        # Prepare logger
        cls.log = logging.getLogger('netapp_puppet_module_tests')
        cls.log.setLevel(logging.DEBUG)
        cls.ch = logging.StreamHandler()
        cls.ch.setLevel(logging.DEBUG)
        cls.log.addHandler(cls.ch)

        cls.log.debug("\n"+"-"*45 +" Tests is starting "+"-"*45 + '\n')

        # Check if 'puppet agent --configprint usecacheonfailure' if false
        cls.log.debug("Puppet agent option 'usecacheonfailure' is set to: " + sh.puppet('agent','--configprint','usecacheonfailure').upper().strip())
        if sh.puppet('agent','--configprint','usecacheonfailure').upper().strip()!='FALSE':
            raise Exception("You need to set Puppet agent option 'usecacheonfailure' on 'false'!")

        # Read config
        cls.log.debug("Reading configuration...")


        cls.url = configuration.server_root_url
        cls.manifest_path = configuration.manifest_path

        cls.first_system_id = configuration.first_system_id
        cls.first_system_ip1 = configuration.first_system_ip1
        cls.first_system_ip2 = configuration.first_system_ip2
        cls.first_system_pass = configuration.first_system_pass
        cls.first_system_test_pass = configuration.first_system_test_pass
        cls.first_system_test_ip = configuration.first_system_test_ip

        cls.second_system_id = configuration.second_system_id
        cls.second_system_ip1 = configuration.second_system_ip1
        cls.second_system_ip2 = configuration.second_system_ip2
        cls.second_system_pass = configuration.second_system_pass

        # Save current site.pp
        cls.bck_manifest_name = cls.manifest_path + \
                                '/site.pp.' + \
                                datetime.datetime.fromtimestamp(time.time()).strftime('%Y-%m-%d_%H:%M:%S') + \
                                '.bck'
        cls.log.debug("Saving original site.pp  to {0}...".format(cls.bck_manifest_name))
        # Hack for local running
        if os.geteuid() != 0:
            sh.sudo('/bin/cp', cls.manifest_path + "/site.pp", cls.bck_manifest_name)
            sh.sudo('/bin/chmod', '664', cls.bck_manifest_name)
        else:
            sh.cp(cls.manifest_path + "/site.pp", cls.bck_manifest_name)
            sh.chmod('664', cls.bck_manifest_name)
        return

########################################################################################################################

    @classmethod
    def tearDownClass(cls):

        cls.log.debug("\n"+"#"*90)

        # Getting back original site.pp
        cls.log.debug("Restoring original site.pp ...")
        if os.geteuid() != 0:
            sh.sudo('/bin/mv', cls.bck_manifest_name, cls.manifest_path + "/site.pp" )
        else:
            sh.mv(cls.bck_manifest_name, cls.manifest_path + "/site.pp")

        return

########################################################################################################################

    def setUp(self):
        self.log.debug('\n\n'+"#"*25+" "+str(self.id())+" "+"#"*25+'\n')

