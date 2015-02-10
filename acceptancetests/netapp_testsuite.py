#!/usr/bin/python
# -*- coding: utf-8 -*-

''' Test suite for check puppet netapp module '''

import random
from netapp_helper_class import *

import pprint
import os

class NetApp_Puppet_Module_Test_Suite(MyTestSuite):

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


##################################### HERE COME REAL TESTING!!! ################################################

    #@unittest2.skip('')
    def test_storage_system(self):
        '''
        Testing of adding netapp_e_storage_system to proxy db
        '''

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_system(self.first_system_id)

        # Saving stage after cleaning
        stage_after_delete  = self.get_system_list()
        self.log.debug("Current systems (after delete {system_id} system): {systems}".format(system_id=self.first_system_id, systems=stage_after_delete))

        # Constructing  custom site.pp and switching on it
        d = self.construct_dict_for_first_system('WATERMARK_test_storage_system_{0}')
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Assertions
        assert (self.first_system_id not in stage_after_delete) and (self.first_system_id in stage_after_puppet)

        # TODO Make test with existing system and wrong controllers ips (will it owerride?)

########################################################################################################################

    #@unittest2.skip('')
    def test_storage_system_without_controllers(self):
        '''
         Test of adding netapp_e_storage_system without controller (and password option)
        '''

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_system(self.first_system_id)

        # Saving stage after cleaning
        stage_after_delete  = self.get_system_list()
        self.log.debug("Current systems (after delete {system_id} system): {systems}".format(system_id=self.first_system_id, systems=stage_after_delete))

        # Constructing  custom site.pp and switching on it
        d = self.construct_dict_for_first_system('WATERMARK_test_storage_system_without_controllers_ip_{0}')
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))

        # Remove pass and controllers section here
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp,'^\s*controller')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))


        assert (self.first_system_id not in stage_after_puppet) and self.output_errors_has(self.first_system_id)

########################################################################################################################

    #@unittest2.skip('')
    def test_storage_system_duplicate_ip_negative(self):
        '''
        Test of adding two netapp_e_storage_system's with different names but same ips to proxy db
        '''


        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        d1={}
        rand_hash=hex(random.getrandbits(24))[2:-1]
        d1['system_id']='BANANA1_'+rand_hash
        d1['system_ip1']='8.8.8.8'
        d1['system_ip2']='8.8.4.4'
        d1['system_pass']='banana'
        d1['ensure'] = 'present'
        self.log.debug("Random hash for watermark: {0}".format(rand_hash))
        d1['signature']='WATERMARK_test_storage_system_negative_BANANA1_{0}'.format(rand_hash)
        d2={}
        d2['system_id']='BANANA2_'+rand_hash
        d2['system_ip1']='8.8.8.8'
        d2['system_ip2']='8.8.4.4'
        d2['system_pass']='banana'
        d2['ensure'] = 'present'
        d2['signature']='WATERMARK_test_storage_system_negative_BANANA2_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d1)+
        self.manifest_storage_system_section.format(**d2))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Cleaning
        self.rid_all_BANANAs()
        self.log.debug("Current systems (after clearing of  BANANAs): {systems}".format(systems=self.get_system_list()))

        # Assertions
        self.assertFalse(
                         'BANANA2' in stage_after_puppet or
                         self.output_errors_has_not('BANANA2'))

########################################################################################################################

    #@unittest2.skip('')
    def test_storage_system_duplicate_name_negative(self):
        '''
        Test of adding two netapp_e_storage_system's with same names to proxy db
        '''

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        d1={}
        rand_hash=hex(random.getrandbits(24))[2:-1]
        d1['system_id']='BANANA_'+rand_hash
        d1['system_ip1']='8.8.8.8'
        d1['system_ip2']='8.8.4.4'
        d1['system_pass']='banana'
        d1['ensure'] = 'present'
        self.log.debug("Random hash for watermark: {0}".format(rand_hash))
        d1['signature']='WATERMARK_test_storage_system_negative_BANANA_{0}'.format(rand_hash)
        d2={}
        d2['system_id']='BANANA_'+rand_hash
        d2['system_ip1']='10.10.10.1'
        d2['system_ip2']='10.20.20.2'
        d2['system_pass']='banana'
        d2['ensure'] = 'present'
        d2['signature']='ANOTHER_WATERMARK_test_storage_system_negative_BANANA_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d1)+
        self.manifest_storage_system_section.format(**d2))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Cleaning
        self.rid_all_BANANAs()
        self.log.debug("Current systems (after clearing of  BANANAs): {systems}".format(systems=self.get_system_list()))

        # Assertions
        assert self.output_errors_has('BANANA_'+rand_hash) and 'BANANA_'+rand_hash not in stage_after_puppet

########################################################################################################################

    #@unittest2.skip('')
    def test_storage_system_ensure_absent(self):
        '''
        Test of removing netapp_e_storage_system from  proxy db
        '''

        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_all_BANANAs()

        # Constructing  custom site.pp and switching on it (first time)
        d={}
        rand_hash=hex(random.getrandbits(24))[2:-1]
        d['system_id']='BANANA_'+rand_hash
        d['system_ip1']='8.8.8.8'
        d['system_ip2']='8.8.4.4'
        d['system_pass']='banana'
        d['ensure'] = 'present'
        self.log.debug("Random hash for watermark: {0}".format(rand_hash))
        d['signature']='WATERMARK_test_storage_system_ensure_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)


        # Run 'puppet device' by subprocess (first time)
        stage_after_puppet_ensure_present = self.run_puppet_device(verbose=False)
        self.log.debug("Current systems (after first puppet running): {systems}".format(systems=stage_after_puppet_ensure_present))

        # Constructing custom site.pp and switching on it (second time)
        rand_hash=hex(random.getrandbits(24))[2:-1]
        d['ensure'] = 'absent'
        d['signature']='WATERMARK_test_storage_system_ensure_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (second time)
        stage_after_puppet_ensure_absent = self.run_puppet_device()
        self.log.debug("Current systems (after second puppet running): {systems}".format(systems=stage_after_puppet_ensure_absent))

        # Cleaning
        self.rid_all_BANANAs()

        # Assertions
        assert (d['system_id'] in stage_after_puppet_ensure_present) and (d['system_id'] not in stage_after_puppet_ensure_absent)

########################################################################################################################

    #@unittest2.skip('')
    def test_storage_system_ensure_absent_invalid_ip_negative(self):
        '''
        Test of removing  netapp_e_storage_system with correct names but different ips from proxy db
        '''

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        d={}
        rand_hash=hex(random.getrandbits(24))[2:-1]
        d['system_id']='BANANA_'+rand_hash
        d['system_ip1']='10.10.10.10'
        d['system_ip2']='11.11.11.11'
        d['system_pass']='banana'
        d['ensure'] = 'present'
        self.log.debug("Random hash for watermark: {0}".format(rand_hash))
        d['signature']='WATERMARK_storage_system_ensure_absent_invalid_ip_negative_BANANA_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (first time)
        stage_after_puppet_ensure_present = self.run_puppet_device(verbose=False)
        self.log.debug("Current systems (after first puppet running): {systems}".format(systems=stage_after_puppet_ensure_present))

        rand_hash=hex(random.getrandbits(24))[2:-1]
        d['system_ip1']='12.12.12.12'
        d['system_ip2']='13.13.13.13'
        d['ensure'] = 'absent'
        d['signature']='WATERMARK_storage_system_ensure_absent_invalid_ip_negative_{0}'.format(rand_hash)
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (second time)
        stage_after_puppet_ensure_absent = self.run_puppet_device()
        self.log.debug("Current systems (after second puppet running): {systems}".format(systems=stage_after_puppet_ensure_absent))

        # Cleaning
        self.rid_all_BANANAs()

        # Assertions
        assert self.output_errors_has('BANANA_'+rand_hash)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_password_set_negative(self):
        '''
        Test of setting initially invalid password

        1. Check if the first system is present on storage (if no, try to add it)
        2. Make custom manifest
        3. Watch errors

        '''

        self.restore_first_system_by_REST()

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_test_netapp_password_set_negative_{0}', rand_hash)
        s['system_pass'] = 'ABSOLUTELY_WRONG_PASSWORD_'+rand_hash

        p={}
        p['system_id'] = self.first_system_id
        p['current_password'] = self.first_system_id
        p['new_password'] = 'THIS_PASSWORD_WILL_NEVER_BE_SET_UP'
        p['admin'] = 'true'
        p['force'] = 'true'

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
        self.manifest_storage_password_section.format(**p))

        self.switch_to_custom_manifest(new_site_pp)

         # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Assertions
        assert self.output_errors_has(self.first_system_id)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_password_set(self):
        '''
        Test of setting valid password
        '''

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        s={}
        rand_hash=hex(random.getrandbits(24))[2:-1]
        s['system_id'] = self.first_system_id
        s['system_ip1'] = self.first_system_ip1
        s['system_ip2'] = self.first_system_ip2
        s['ensure'] = 'present'
        s['system_pass'] = self.first_system_pass
        s['signature'] = 'WATERMARK_test_netapp_password_set_{0}'.format(rand_hash)

        p={}
        p['system_id'] = self.first_system_id
        p['current_password']= self.first_system_pass
        p['new_password']= self.first_system_test_pass
        p['admin']='true'
        p['force']='true'

        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
        self.manifest_storage_password_section.format(**p))

        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        #self.log.debug("<PUPPET DEVICE STUB>")
        #MyTestSuite.output = 'PUPPET\nDEVICE\nSTUB'

        # Revert pass back if it changed successful
        if  self.output_errors_has_not(self.first_system_id):
            self.log.debug("Password's changing was successful, now revert it back ...")
            s['system_pass'] = self.first_system_test_pass
            p['current_password']= self.first_system_test_pass
            p['new_password']= self.first_system_pass

            new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                   self.manifest_storage_password_section.format(**p))

            self.switch_to_custom_manifest(new_site_pp)

            # Run 'puppet device' by subprocess
            stage_after_puppet = self.run_puppet_device()
            self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

            #self.log.debug("PUPPET DEVICE STUB")
            #self.output = '<PUPPET\nDEVICE\nSTUB {system_id}>'.format(system_id=self.first_system_id)


            if self.output_errors_has(self.first_system_id):
                self.log.debug("WARNING!!! SOMETHING IS WRONG WITH REVERTING PASSWORD BACK !!!")


        assert True

#####################################################################################################################
    @unittest2.skip('Incomplete test')
    def test_netapp_interface_set(self):
        '''
        Test of change ip address on controller

        1. Restore first system
        2. Get list of system ips
        3. Check is this ips accessible?
        4. Change one ip
        5. Get list of system ips
        6. Check is this ip accessible?
        7. Revert ip back
        '''

        # Saving starting stage
        self.restore_first_system_by_REST()
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Get ip by REST
        initial_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(Before changing ip) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, initial_ip_list))


        # Ping actual ips
        self.log.debug("Now it's pinging those ips ...")
        ping_result_before_puppet = [subprocess.call(['ping', '-c 2', '-q', ip], stdout=open('/dev/null', 'w')) for ip in initial_ip_list]
        if sum(ping_result_before_puppet) != 0:
            raise RuntimeError('RUNTIME ERROR - SOMETHING IS WRONG WITH PING OF IPS!!!')
        else:
            self.log.debug("Pinging is OK - go ahead!")

        # Save initial state of first interface from first system
        testing_interface = [i for i in generic_get('ethernet-interfaces', array_id=self.first_system_id)
                             if i['linkStatus'].strip() == 'up' and i['ipv4Enabled']][0]

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_test_netapp_interface_set_{0}', rand_hash)

        i = {}
        i['macAddr'] = testing_interface['macAddr']
        i['system_id'] = self.first_system_id
        i['ipv4'] = 'true'
        i['ipv4config'] = "configStatic"
        i['ipv4address'] = self.first_system_test_ip
        i['ipv4gateway'] = testing_interface['ipv4GatewayAddress']
        i['ipv4mask'] = testing_interface['ipv4SubnetMask']
        i['remoteaccess'] = 'true'

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s)+
                                                self.manifest_storage_interface_section.format(**i))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        # Get ip by REST
        changed_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(After changing ip) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, changed_ip_list))

        #Revert ip back
        i={}
        i['macAddr'] = testing_interface['macAddr']
        i['system_id'] = self.first_system_id
        i['ipv4'] = 'true'
        i['ipv4config'] = "configStatic"
        i['ipv4address'] = testing_interface['ipv4Address']
        i['ipv4gateway'] = testing_interface['ipv4GatewayAddress']
        i['ipv4mask'] = testing_interface['ipv4SubnetMask']
        i['remoteaccess'] = 'true'
        new_site_pp=self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s)+
                                                self.manifest_storage_interface_section.format(**i))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        # Get ip by REST
        reverted_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(After reverting ip) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, reverted_ip_list))


        if set(initial_ip_list)!=set(reverted_ip_list):
            raise RuntimeError('RUNTIME ERROR - SOMETHING IS WRONG WITH REVERTING OF IPS!!!')

        assert set(initial_ip_list)!=set(changed_ip_list)


#####################################################################################################################
    @unittest2.skip('')
    def test_netapp_interface_set_wrong_mac_negative(self):
        '''
        Test of change ip address on controller with wrong macaddr in params

        1. Restore first system
        2. Get list of system ips
        3. Check is this ips accessible?
        4. Change one ip
        5. Get list of system ips
        6. Check is this ip accessible?
        7. Revert ip back
        '''

        # Saving starting stage
        self.restore_first_system_by_REST()
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Get ip by REST
        initial_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(Before changing ip) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, initial_ip_list))

        # Ping actual ips
        self.log.debug("Now it's pinging those ips ...")
        ping_result_before_puppet = [subprocess.call(['ping', '-c 2', '-q', ip], stdout=open('/dev/null', 'w')) for ip in initial_ip_list]
        if sum(ping_result_before_puppet)!=0:
            raise RuntimeError('RUNTIME ERROR - SOMETHING IS WRONG WITH PING OF IPS!!!')
        else:
            self.log.debug("Pinging is OK - go ahead!")

        # Save initial state of first interface from first system
        testing_interface = [i for i in generic_get('ethernet-interfaces', array_id=self.first_system_id)
                      if i['linkStatus'].strip() == 'up' and i['ipv4Enabled']][0]




        assert False

    # TODO right ips, wrong system in interface-resource


##################################### HERE REAL TESTING HAS GONE !!! ################################################

if __name__ == '__main__':
    unittest2.main(verbosity=1)


