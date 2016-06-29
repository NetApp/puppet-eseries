#!/usr/bin/python
# -*- coding: utf-8 -*-

""" Test suite for check puppet netapp module """


from netapp_helper_class import *


class NetApp_Puppet_Module_Test_Suite(MyTestSuite):

# TODO make switch to custom manifest automatic (by new_site_pp -> self.new_site_pp)?
# TODO Review text of debug-messages
# TODO Make all creation tests create two items at once!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# TODO Tests with long name
# TODO Verify watermarks
# TODO pool_before of pool_list_before? Get it in accordance!!!
# TODO Add has_error('BANANA') to every puppet-run?



##################################### HERE COME REAL TESTING!!! ################################################

    #@unittest2.skip('')
    def test_netapp_storage_system(self):
        """
        Testing of adding netapp_e_storage_system to proxy db
        """

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_system(self.first_system_id)

        # Saving stage after cleaning
        stage_after_delete = self.get_system_list()
        self.log.debug("Current systems (after delete {system_id} system): {systems}".format(system_id=self.first_system_id,
                                                                                             systems=stage_after_delete))

        # Constructing  custom site.pp and switching on it
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Assertions
        assert (self.first_system_id not in stage_after_delete) and (self.first_system_id in stage_after_puppet)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_system_without_controllers(self):
        """
         Test of adding netapp_e_storage_system without controller (and password option)
        """

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_system(self.first_system_id)

        # Saving stage after cleaning
        stage_after_delete = self.get_system_list()
        self.log.debug("Current systems (after delete {system_id} system): {systems}".format(system_id=self.first_system_id, systems=stage_after_delete))

        # Constructing  custom site.pp and switching on it
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s))

        # Remove pass and controllers section here
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, '^\s*controller')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        # Assertions
        assert (self.first_system_id not in stage_after_puppet) and self.output_errors_has(self.first_system_id)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_system_duplicate_ip_negative(self):
        """
        Test of adding two netapp_e_storage_system's with different names but same ips to proxy db
        """


        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        d1 = dict()
        rand_hash = hex(random.getrandbits(24))[2:-1]
        d1['system_id'] = 'BANANA1_'+rand_hash
        d1['system_ip1'] = '8.8.8.8'
        d1['system_ip2'] = '8.8.4.4'
        d1['system_pass'] = 'banana'
        d1['ensure'] = 'present'
        self.log.debug("Random hash for watermark: {0}".format(rand_hash))
        d1['signature'] = 'WATERMARK_{1}_BANANA1_{0}'.format(rand_hash, self.case_short_name(self.id()))
        d2 = dict()
        d2['system_id'] = 'BANANA2_'+rand_hash
        d2['system_ip1'] = '8.8.8.8'
        d2['system_ip2'] = '8.8.4.4'
        d2['system_pass'] = 'banana'
        d2['ensure'] = 'present'
        d2['signature'] = 'WATERMARK_{1}_BANANA2_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d1) +
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

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_system_duplicate_name_negative(self):
        """
        Test of adding two netapp_e_storage_system's with same names to proxy db
        """

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        d1 = dict(system_id='BANANA_'+rand_hash,
                  system_ip1='8.8.8.8',
                  system_ip2='8.8.4.4',
                  system_pass='banana',
                  ensure='present',
                  signature='WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id())))

        d2 = dict()
        d2['system_id'] = 'BANANA_'+rand_hash
        d2['system_ip1'] = '10.10.10.1'
        d2['system_ip2'] = '10.20.20.2'
        d2['system_pass'] = 'banana'
        d2['ensure'] = 'present'
        d2['signature'] = 'ANOTHER_WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d1) +
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

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_system_ensure_absent(self):
        """
        Test of removing netapp_e_storage_system from  proxy db
        """

        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Preliminary cleaning of proxy db
        self.rid_all_BANANAs()

        # Constructing  custom site.pp and switching on it (first time)
        d = dict()
        rand_hash = hex(random.getrandbits(24))[2:-1]
        d['system_id'] = 'BANANA_'+rand_hash
        d['system_ip1'] = '8.8.8.8'
        d['system_ip2'] = '8.8.4.4'
        d['system_pass'] = 'banana'
        d['ensure'] = 'present'
        d['signature'] = 'WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (first time)
        stage_after_puppet_ensure_present = self.run_puppet_device(verbose=False)
        self.log.debug("Current systems (after first puppet running): {systems}".format(systems=stage_after_puppet_ensure_present))

        # Constructing custom site.pp and switching on it (second time)
        rand_hash = hex(random.getrandbits(24))[2:-1]
        d['ensure'] = 'absent'
        d['signature'] = 'WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (second time)
        stage_after_puppet_ensure_absent = self.run_puppet_device()
        self.log.debug("Current systems (after second puppet running): {systems}".format(systems=stage_after_puppet_ensure_absent))

        # Cleaning
        self.rid_all_BANANAs()

        # Assertions
        assert d['system_id'] in stage_after_puppet_ensure_present and \
               d['system_id'] not in stage_after_puppet_ensure_absent

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_system_ensure_absent_invalid_ip_negative(self):
        """
        Test of removing  netapp_e_storage_system with correct names but different ips from proxy db
        """

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        d = {}
        rand_hash = hex(random.getrandbits(24))[2:-1]
        d['system_id'] = 'BANANA_'+rand_hash
        d['system_ip1'] = '10.10.10.10'
        d['system_ip2'] = '11.11.11.11'
        d['system_pass'] = 'banana'
        d['ensure'] = 'present'
        d['signature'] = 'WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess (first time)
        stage_after_puppet_ensure_present = self.run_puppet_device(verbose=False)
        self.log.debug("Current systems (after first puppet running): {systems}".format(systems=stage_after_puppet_ensure_present))

        rand_hash = hex(random.getrandbits(24))[2:-1]
        d['system_ip1'] = '12.12.12.12'
        d['system_ip2'] = '13.13.13.13'
        d['ensure'] = 'absent'
        d['signature'] = 'WATERMARK_{1}_BANANA_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**d))
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
        """
        Test of setting initially invalid password

        1. Check if the first system is present on storage (if no, try to add it)
        2. Make custom manifest
        3. Watch errors
        """

        self.restore_first_system_by_REST()

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)
        s['system_pass'] = 'ABSOLUTELY_WRONG_PASSWORD_'+rand_hash
        p = dict()
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
        """
        Test of setting valid password
        """

        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))

        # Constructing  custom site.pp and switching on it
        s = dict()
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s['system_id'] = self.first_system_id
        s['system_ip1'] = self.first_system_ip1
        s['system_ip2'] = self.first_system_ip2
        s['ensure'] = 'present'
        s['system_pass'] = self.first_system_pass
        s['signature'] = 'WATERMARK_{1}_{0}'.format(rand_hash, self.case_short_name(self.id()))
        p = dict()
        p['system_id'] = self.first_system_id
        p['current_password'] = self.first_system_pass
        p['new_password'] = self.first_system_test_pass
        p['admin'] = 'true'
        p['force'] = 'true'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_password_section.format(**p))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        stage_after_puppet = self.run_puppet_device()
        self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

        if self.output_errors_has(self.first_system_id):
            raise RuntimeError("WARNING!!! SOMETHING IS WRONG WITH CHANGING PASSWORD!!!")

        # Revert pass back if it changed successful
        if self.output_errors_has_not(self.first_system_id):
            self.log.debug("Password's changing was successful, now revert it back ...")
            s['system_pass'] = self.first_system_test_pass
            p['current_password'] = self.first_system_test_pass
            p['new_password'] = self.first_system_pass

            new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                     self.manifest_storage_password_section.format(**p))

            self.switch_to_custom_manifest(new_site_pp)

            # Run 'puppet device' by subprocess
            stage_after_puppet = self.run_puppet_device()
            self.log.debug("Current systems (after puppet running): {systems}".format(systems=stage_after_puppet))

            if self.output_errors_has(self.first_system_id):
                raise RuntimeError("WARNING!!! SOMETHING IS WRONG WITH REVERTING PASSWORD BACK !!!")

        #Assertions (true if there were no previous exceptions)
        assert True

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_interface_set(self):
        """
        Test of change ip address on controller

        1. Restore first system
        2. Get list of system ips
        3. Check is this ips accessible?
        4. Change one ip
        5. Get list of system ips
        6. Check is this ip accessible?
        7. Revert ip back
        """

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
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())))
        i = dict()
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
        i = dict()
        i['macAddr'] = testing_interface['macAddr']
        i['system_id'] = self.first_system_id
        i['ipv4'] = 'true'
        i['ipv4config'] = "configStatic"
        i['ipv4address'] = testing_interface['ipv4Address']
        i['ipv4gateway'] = testing_interface['ipv4GatewayAddress']
        i['ipv4mask'] = testing_interface['ipv4SubnetMask']
        i['remoteaccess'] = 'true'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_interface_section.format(**i))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        # Get ip by REST
        reverted_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(After reverting ip) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, reverted_ip_list))


        if set(initial_ip_list) != set(reverted_ip_list):
            raise RuntimeError('RUNTIME ERROR - SOMETHING IS WRONG WITH REVERTING OF IPS!!!')

        # Assertions
        assert set(initial_ip_list) != set(changed_ip_list)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_interface_set_wrong_mac_negative(self):
        """
        Test of change ip address on controller with wrong mac addr in params

        1. Restore first system
        2. Get list of system ips
        3. Check is this ips accessible?
        4. Try to change one ip
        5. Get list of system ips
        6. Check is this ip accessible?
        7. Revert ip back
        """

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
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())))
        i = dict()
        test_mac = self.get_random_mac()
        i['macAddr'] = test_mac
        i['system_id'] = self.first_system_id
        i['ipv4'] = 'true'
        i['ipv4config'] = "configStatic"
        i['ipv4address'] = self.first_system_test_ip
        i['ipv4gateway'] = testing_interface['ipv4GatewayAddress']
        i['ipv4mask'] = testing_interface['ipv4SubnetMask']
        i['remoteaccess'] = 'true'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_interface_section.format(**i))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        # Get ip by REST
        changed_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(After fail attempt) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, changed_ip_list))

        # Assertions
        assert initial_ip_list == changed_ip_list and self.output_errors_has(test_mac)

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_interface_set_wrong_system_negative(self):
        """
        Test of change ip address on controller with wrong system id in params

        1. Restore first system
        2. Get list of system ips
        3. Check is this ips accessible?
        4. Try to change one ip
        5. Get list of system ips
        6. Check is this ip accessible?
        7. Revert ip back
        """

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
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)
        i = dict(macAddr=testing_interface['macAddr'],
                 system_id='BANANA_{0}'.format(rand_hash),
                 ipv4='true',
                 ipv4config="configStatic",
                 ipv4address=self.first_system_test_ip,
                 ipv4gateway=testing_interface['ipv4GatewayAddress'],
                 ipv4mask=testing_interface['ipv4SubnetMask'],
                 remoteaccess='true')

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_interface_section.format(**i))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        # Get ip by REST
        changed_ip_list = self.get_ips_by_REST(self.first_system_id)
        message = "(After fail attempt) List of ethernet interfaces of system '{0}' (with 'up' state and true in 'ipv4Enabled'): {1}"
        self.log.debug(message.format(self.first_system_id, changed_ip_list))

        # Assertions
        assert initial_ip_list == changed_ip_list and self.output_errors_has(testing_interface['macAddr'])

#####################################################################################################################

    # TODO Make test with right sys id in interface section but wrong in storage section?
    # TODO Make test with right sys id in interface section but without storage section?

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_storage_pool_create_delete(self):
        """
        Test of storage pool creation

        0. get pools list
        1. Select 2 free disks
        2. Create raid0 pool by manifest
        3. Select by REST this pool and disks
        4. Delete this pool
        5. Try to select by REST this pool and disks
        """

        self.restore_first_system_by_REST()

        # Saving starting stage
        stage_on_start = self.get_system_list()
        pool_list_before = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of pools: {0}".format(pool_list_before))

        # Select 2 free disks
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_create = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        self.log.debug("(after creating manifest) List of pools: {0}".format(pool_list_after_create))

        p['ensure'] = 'absent'
        s['signature'] = 'WATERMARK_{1}_delete_{0}'.format(rand_hash, self.case_short_name(self.id()))

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p))
        # Remove redundant params
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'raidlevel')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'diskids')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_delete = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        self.log.debug("(after deleting manifest) List of pools: {0}".format(pool_list_after_delete))

        # Assertions
        assert p['pool_id'] in pool_list_after_create and p['pool_id'] not in pool_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_simple_volume_create_delete(self):

        """
        Test of creation and deletion simple volume

        1. Create pool
        2. Create volume
        3. Delete volume
        4. Delete pool
        """

        self.restore_first_system_by_REST()

        # Saving starting stage
        stage_on_start = self.get_system_list()
        pool_list_before = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_before = [j['name'] for j in generic_get('volumes', array_id=self.first_system_id)]

        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of pools: {0}".format(pool_list_before))
        self.log.debug("(before manifests) List of volumes: {0}".format(volume_list_before))

        # Select free disks
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))

        v = dict(volume_id='BANANA_VOLUME_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='1',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='false')

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v))

        # TODO Dependencies!!!!
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_create = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_create = [j['name'] for j in generic_get('volumes', array_id=self.first_system_id)]
        self.log.debug("(after creating manifest) List of pools: {0}".format(pool_list_after_create))
        self.log.debug("(after creating manifests) List of volumes: {0}".format(volume_list_after_create))

        p['ensure'] = 'absent'
        v['ensure'] = 'absent'
        s['signature'] = 'WATERMARK_{1}_delete_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_delete = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_delete = [j['name'] for j in generic_get('volumes', array_id=self.first_system_id)]
        self.log.debug("(after deleting manifest) List of pools: {0}".format(pool_list_after_delete))
        self.log.debug("(after deleting manifests) List of volumes: {0}".format(volume_list_after_delete))

        assert v['volume_id'] in volume_list_after_create and v['volume_id'] not in volume_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_thin_volume_create_delete(self):
        """
        Test of creation and deleting simple volume

        1. Create pool
        2. Create volume
        3. Delete volume
        4. Delete pool
        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        pool_list_before = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_before = [j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)]

        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of pools: {0}".format(pool_list_before))
        self.log.debug("(before manifests) List of thin_volumes: {0}".format(volume_list_before))

        # Select free disks
        free_disks = self.get_free_disk(self.first_system_id, number=12)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)


        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raidDiskPool',
                 diskids="{0}".format(free_disks))

        v = dict(volume_id='BANANA_VOLUME_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='1',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='true')

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v))

        new_site_pp = self.insert_line_to_multiline_regexp(new_site_pp,
                                                           'thin\s*=>',
                                                           '      repositorysize    => 10,')
        new_site_pp = self.insert_line_to_multiline_regexp(new_site_pp,
                                                           'repositorysize',
                                                           '      maxrepositorysize => 15,')

        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_create = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_create = [j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)]
        self.log.debug("(after creating manifest) List of pools: {0}".format(pool_list_after_create))
        self.log.debug("(after creating manifests) List of thin_volumes: {0}".format(volume_list_after_create))

        p['ensure'] = 'absent'
        v['ensure'] = 'absent'
        s['signature'] = 'WATERMARK_{1}_delete_{0}'.format(rand_hash, self.case_short_name(self.id()))
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 r'Netapp_e_volume <| |> -> Netapp_e_storage_pool <| |>')

        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'require')

        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_delete = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_delete = [j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)]
        self.log.debug("(after deleting manifest) List of pools: {0}".format(pool_list_after_delete))
        self.log.debug("(after deleting manifests) List of volumes: {0}".format(volume_list_after_delete))

        assert v['volume_id'] in volume_list_after_create and v['volume_id'] not in volume_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_volume_copy_create_delete(self):
        """
        Test of volume copy

        1. Create pool and two disks
        2. Create a new volume copy pair
        3. Get the list of volume copy pairs
        4. Start/Stop a copy pair operation
        5. Delete copy pair
        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        pool_list_before = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_before = [j['name'] for j in generic_get('volumes', array_id=self.first_system_id)]
        volume_copies_list_before = [j['id'] for j in generic_get('volume_copies', array_id=self.first_system_id)]

        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of pools: {0}".format(pool_list_before))
        self.log.debug("(before manifests) List of volumes: {0}".format(volume_list_before))
        self.log.debug("(before manifests) List of volume copies: {0}".format(volume_copies_list_before))

        # Select free disks
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]

        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))

        v1 = dict(volume_id='BANANA_VOLUME_SOURCE_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  size='1',
                  pool_id=p['pool_id'],
                  sizeunit='gb',
                  segsize='512',
                  thin='false')

        v2 = dict(volume_id='BANANA_VOLUME_TARGET_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  size='1',
                  pool_id=p['pool_id'],
                  sizeunit='gb',
                  segsize='512',
                  thin='false')

        c = dict(volume_copy_id='BANANA_COPY_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 source_volume='BANANA_VOLUME_SOURCE_{0}'.format(rand_hash),
                 target_volume='BANANA_VOLUME_TARGET_{0}'.format(rand_hash),
                 priority='priority3',
                 targetwriteprotected='true',
                 disablesnapshot='false',
                 )

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v1) +
                                                 self.manifest_storage_volume_section.format(**v2) +
                                                 self.manifest_storage_volume_copy_section.format(**c) +
                                                 r'Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> -> Netapp_e_volume_copy <| |>'
                                                 )
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_create = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_create = [j['name'] for j in generic_get('volumes', array_id=self.first_system_id)]
        volume_copies_list_after_create = [j['id'] for j in generic_get('volume_copies', array_id=self.first_system_id)]
        self.log.debug("(after creating manifest) List of pools: {0}".format(pool_list_after_create))
        self.log.debug("(after creating manifests) List of volumes: {0}".format(volume_list_after_create))
        self.log.debug("(after creating manifests) List of volume copies: {0}".format(volume_copies_list_after_create))

        # Remove
        p['ensure'] = 'absent'
        v1['ensure'] = 'absent'
        v2['ensure'] = 'absent'
        c['ensure'] = 'absent'

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v1) +
                                                 self.manifest_storage_volume_section.format(**v2) +
                                                 self.manifest_storage_volume_copy_section.format(**c) +
                                                 r'Netapp_e_volume_copy <| |> -> Netapp_e_volume <| |> -> Netapp_e_storage_pool <| |>'
                                                 )

        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'require')
        # TODO replace name with some funny word - will it work?

        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        pool_list_after_delete = [j['label'] for j in generic_get('pools', array_id=self.first_system_id)]
        volume_list_after_delete = [j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)]
        volume_copies_list_after_delete = [j['id'] for j in generic_get('volume_copies', array_id=self.first_system_id)]
        self.log.debug("(after deleting manifest) List of pools: {0}".format(pool_list_after_delete))
        self.log.debug("(after deleting manifests) List of volumes: {0}".format(volume_list_after_delete))
        self.log.debug("(after deleting manifests) List of volume copies: {0}".format(volume_copies_list_after_delete))

        # Assertions
        assert set(volume_copies_list_after_create) != set(volume_copies_list_before) and \
               'BANANA_COPY_{0}'.format(rand_hash) not in volume_copies_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_hostgroup_empty_create_delete(self):

        """
        Test of creating/deleting host group

        1. Read group list by REST
        2. Create group by manifest
        3. Read group list by REST
        2. Create group by manifest
        3. Read group list by REST
        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        hostgroups_before = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_before_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of hostgroups: {0}".format(hostgroups_before_for_print))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        hg = dict(hostgroup_id='BANANA_HOSTGROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id)

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_create = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_after_create_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("(after creation manifest) List of hostgroups: {0}".format(hostgroups_after_create_for_print))

        # Remove
        hg['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_delete = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_after_delete_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("(after deletion manifest) List of hostgroups: {0}".format(hostgroups_after_delete_for_print))

        # Assertions
        assert set(hostgroups_before) != set(hostgroups_after_create) and \
               'BANANA_HOSTGROUP_{0}'.format(rand_hash) not in hostgroups_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_hostgroup_delete_negative(self):
        """
        Test of non-existent hostgroup deleting
        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        hostgroups_before = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_before_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of hostgroups: {0}".format(hostgroups_before_for_print))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        hg = dict(hostgroup_id='BANANA_HOSTGROUP_{0}'.format(rand_hash),
                  ensure='absent',
                  system_id=self.first_system_id)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_create = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_after_create_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("(after creation manifest) List of hostgroups: {0}".format(hostgroups_after_create_for_print))

        #TODO Assertions
        assert self.output_errors_has('BANANA_HOSTGROUP_{0}'.format(rand_hash))

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_hostgroup_duplicate_negative(self):
        """
        Test of duplicate hostgroup creating

        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        hostgroups_before = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_before_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of hostgroups: {0}".format(hostgroups_before_for_print))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        hg1 = dict(hostgroup_id='BANANA_HOSTGROUP_DUPLICATE_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id)
        hg2 = dict(hostgroup_id='BANANA_HOSTGROUP_DUPLICATE_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg1) +
                                                 self.manifest_storage_hostgroup_section.format(**hg2))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_create = [j['id'] for j in generic_get('host_groups', array_id=self.first_system_id)]
        hostgroups_after_create_for_print = ["'{1}'({0})".format(j['id'],j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        self.log.debug("(after creation manifest) List of hostgroups: {0}".format(hostgroups_after_create_for_print))

        #Assertions
        assert 'BANANA_HOSTGROUP_DUPLICATE_{0}'.format(rand_hash) not in hostgroups_after_create

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_host_create_delete(self):
        """
        Test of  host creation/deletion

        1. Get host list
        2. Create hostgroup
        3. Create host with random type from host-types
        4. Delete host

        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_list()
        hostgroups_before_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        hosts_before = [j['label'] for j in generic_get('hosts', array_id=self.first_system_id)]
        hosts_before_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('hosts', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of hostgroups: {0}".format(hostgroups_before_for_print))
        self.log.debug("(before manifests) List of hosts: {0}".format(hosts_before_for_print))

        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        hg = dict(hostgroup_id='BANANA_HOSTGROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id)
        port_types = [ 'iscsi', ]# ['notImplemented', 'scsi', 'fc', 'sata', 'sas', 'iscsi', 'ib', 'fcoe', '__UNDEFINED']

        p1 = "{{type => '{type}', port => '{port}', label => '{label}'}}".format(type=random.choice(port_types),
                                                                                 port='iqn.1998-05.com.osx:cd1234abcdef',
                                                                                 label='BANANA_PORT_ONE_{0}'.format(rand_hash))
        p2 = "{{type => '{type}', port => '{port}', label => '{label}'}}".format(type=random.choice(port_types),
                                                                                 port='iqn.1998-05.com.windows:cd42b74121212',
                                                                                 label='BANANA_PORT_TWO_{0}'.format(rand_hash))
        ports = "[{0},\n\t\t\t {1}]".format(p1, p2)
        h = dict(host_id='BANANA_HOST_{0}'.format(rand_hash),
                 ensure='present',
                 typeindex=random.choice([i['index'] for i in generic_get('host_types', array_id=self.first_system_id)]),
                 system_id=self.first_system_id,
                 hostgroup_id=hg['hostgroup_id'],
                 ports=ports)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg) +
                                                 self.manifest_storage_host_section.format(**h) +
                                                 'Netapp_e_host_group <| |> -> Netapp_e_host <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_create_for_print = ["'{1}'({0})".format(j['id'],j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        hosts_after_create = [j['label'] for j in generic_get('hosts', array_id=self.first_system_id)]
        hosts_after_create_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('hosts', array_id=self.first_system_id)]
        self.log.debug("(after creation manifest) List of hostgroups: {0}".format(hostgroups_after_create_for_print))
        self.log.debug("(after creation manifests) List of hosts: {0}".format(hosts_after_create_for_print))

        h['ensure'] = 'absent'
        # TODO Change type and other things - will it work?
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_hostgroup_section.format(**hg) +
                                                 self.manifest_storage_host_section.format(**h))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        hostgroups_after_delete_for_print = ["'{1}'({0})".format(j['id'],j['label']) for j in generic_get('host_groups', array_id=self.first_system_id)]
        hosts_after_delete = [j['label'] for j in generic_get('hosts', array_id=self.first_system_id)]
        hosts_after_delete_for_print = ["'{1}'({0})".format(j['id'], j['label']) for j in generic_get('hosts', array_id=self.first_system_id)]
        self.log.debug("(after deletion manifest) List of hostgroups: {0}".format(hostgroups_after_delete_for_print))
        self.log.debug("(after deletion manifests) List of hosts: {0}".format(hosts_after_delete_for_print))

        self.remove_BANANA_objects_by_REST(self.first_system_id)

        #Assertions
        assert 'BANANA_HOST_{0}'.format(rand_hash) in hosts_after_create \
               and 'BANANA_HOST_{0}'.format(rand_hash) not in hosts_after_delete

#####################################################################################################################

    # TODO map
    # TODO snapshot_volume
    # TODO snapshot_image

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_snapshot_group_create_delete(self):
        """
        Test of creation/deletion snapshot_group

        1. Get initial objects list
        2. Create pool (large :)) and base volume
        3. Create snapshot group pointed to this base volume

        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_state(self.first_system_id)

        self.log.debug("Current systems (before test): {0}".format(stage_on_start['storage_systems']))
        self.log.debug("(before manifests) List of pools: {0}".format(stage_on_start['pools']))
        self.log.debug("(before manifests) List of volumes: {0}".format(stage_on_start['volumes']))
        self.log.debug("(before manifests) List of thin volumes: {0}".format(stage_on_start['thin_volumes']))
        self.log.debug("(before manifests) List of snapshot groups: {0}".format(stage_on_start['snapshot_groups_for_print']))

        # Constructing  custom site.pp and switching on it
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))
        v = dict(volume_id='BANANA_VOLUME_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='3',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='false')
        sg = dict(snapshot_group_id='BANANA_SNAPSHOT_GROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  pool_id=p['pool_id'],
                  volume_id=v['volume_id'],
                  repositorysize='30',
                  warnthreshold='75',
                  policy='purgepit', # ['unknown', 'failbasewrites', 'purgepit', '__UNDEFINED']
                  limit='7',
                  )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_snapshot_group_section.format(**sg)+
                                                 'Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> -> Netapp_e_snapshot_group  <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_create = self.get_system_state(self.first_system_id)
        self.log.debug("(after creation manifests) List of pools: {0}".format(stage_after_create['pools']))
        self.log.debug("(after creation manifests) List of volumes: {0}".format(stage_after_create['volumes']))
        self.log.debug("(after creation manifests) List of thin volumes: {0}".format(stage_after_create['thin_volumes']))
        self.log.debug("(after creation manifests) List of snapshot groups: {0}".format(stage_after_create['snapshot_groups_for_print']))

        # Remove
        sg['ensure'] = 'absent'
        v['ensure'] = 'absent'
        p['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_snapshot_group_section.format(**sg) +
                                                 'Netapp_e_snapshot_group <| |> -> Netapp_e_volume <| |> -> Netapp_e_storage_pool <| |>')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'require')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_delete = self.get_system_state(self.first_system_id)
        self.log.debug("(after deletion manifests) List of pools: {0}".format(stage_after_delete['pools']))
        self.log.debug("(after deletion manifests) List of volumes: {0}".format(stage_after_delete['volumes']))
        self.log.debug("(after deletion manifests) List of thin volumes: {0}".format(stage_after_delete['thin_volumes']))
        self.log.debug("(after deletion manifests) List of snapshot groups: {0}".format(stage_after_delete['snapshot_groups_for_print']))

        self.remove_BANANA_objects_by_REST(self.first_system_id)

        #Assertions
        assert sg['snapshot_group_id'] in stage_after_create['snapshot_groups'] \
            and sg['snapshot_group_id'] not in stage_after_delete['snapshot_groups']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_snapshot_image_create_delete(self):
        """
        Test of snapshot creation/deletion

        """

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_state(self.first_system_id)

        self.log.debug("Current systems (before test): {0}".format(stage_on_start['storage_systems']))
        self.log.debug("(before manifests) List of pools: {0}".format(stage_on_start['pools']))
        self.log.debug("(before manifests) List of volumes: {0}".format(stage_on_start['volumes']))
        self.log.debug("(before manifests) List of thin volumes: {0}".format(stage_on_start['thin_volumes']))
        self.log.debug("(before manifests) List of snapshot groups: {0}".format(stage_on_start['snapshot_groups_for_print']))
        self.log.debug("(before manifests) List of snapshot images: {0}".format(stage_on_start['snapshots_for_print']))

        # Constructing  custom site.pp and switching on it
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))
        v = dict(volume_id='BANANA_VOLUME_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='3',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='false')
        sg = dict(snapshot_group_id='BANANA_SNAPSHOT_GROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  pool_id=p['pool_id'],
                  volume_id=v['volume_id'],
                  repositorysize='30',
                  warnthreshold='75',
                  policy='purgepit', # ['unknown', 'failbasewrites', 'purgepit', '__UNDEFINED']
                  limit='7',
                  )
        i = dict(snapshot_image_id='BANANA_IMAGE_{0}'.format(rand_hash),
                 snapshot_group_id=sg['snapshot_group_id'],
                 system_id=self.first_system_id)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_snapshot_group_section.format(**sg) +
                                                 self.manifest_storage_snapshot_image_section.format(**i) +
                                                 'Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> -> Netapp_e_snapshot_group  <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_create = self.get_system_state(self.first_system_id)
        self.log.debug("(after creation manifests) List of pools: {0}".format(stage_after_create['pools']))
        self.log.debug("(after creation manifests) List of volumes: {0}".format(stage_after_create['volumes']))
        self.log.debug("(after creation manifests) List of thin volumes: {0}".format(stage_after_create['thin_volumes']))
        self.log.debug("(after creation manifests) List of snapshot groups: {0}".format(stage_after_create['snapshot_groups_for_print']))
        self.log.debug("(after creation manifests) List of snapshot images: {0}".format(stage_after_create['snapshots_for_print']))

        self.remove_BANANA_objects_by_REST(self.first_system_id)

        #Assertions
        # Check any snapshot_id points to correct group and volume
        assertion = False

        for i in set(stage_after_create['snapshots']) - set(stage_on_start['snapshots']):
            tmp = stage_after_create['snapshots_for_assertion'][i]
            if tmp['group'] == sg['snapshot_group_id'] and tmp['volume'] == v['volume_id']:
                assertion = True

        assert assertion

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_snapshot_volume_create_delete(self):
        """
        Test of snapshot volume creation/deletion
        1. Create pool->volume->snapshotgroup->snapsot_image
        2. Get id of created snapshot image
        3. Create snapshot volume
        """
        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_state(self.first_system_id)
        self.log.debug("Current systems (before test): {0}".format(stage_on_start['storage_systems']))
        self.log.debug("(before manifests) List of pools: {0}".format(stage_on_start['pools']))
        self.log.debug("(before manifests) List of volumes: {0}".format(stage_on_start['volumes']))
        self.log.debug("(before manifests) List of thin volumes: {0}".format(stage_on_start['thin_volumes']))
        self.log.debug("(before manifests) List of snapshot groups: {0}".format(stage_on_start['snapshot_groups_for_print']))
        self.log.debug("(before manifests) List of snapshot images: {0}".format(stage_on_start['snapshots_for_print']))
        self.log.debug("(before manifests) List of snapshot volumes: {0}".format(stage_on_start['snapshot_volumes']))

        # Constructing  custom site.pp and switching on it (CREATE SNAPSHOT IMAGE)
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)

        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))
        v = dict(volume_id='BANANA_VOLUME_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='3',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='false')
        sg = dict(snapshot_group_id='BANANA_SNAPSHOT_GROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  pool_id=p['pool_id'],
                  volume_id=v['volume_id'],
                  repositorysize='30',
                  warnthreshold='75',
                  policy='purgepit',  # ['unknown', 'failbasewrites', 'purgepit', '__UNDEFINED']
                  limit='7',
                  )
        i = dict(snapshot_image_id='BANANA_IMAGE_{0}'.format(rand_hash),
                 snapshot_group_id=sg['snapshot_group_id'],
                 system_id=self.first_system_id)

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_snapshot_group_section.format(**sg) +
                                                 self.manifest_storage_snapshot_image_section.format(**i) +
                                                 'Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> -> Netapp_e_snapshot_group  <| |> -> Netapp_e_snapshot_image <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_create_snapshot_image = self.get_system_state(self.first_system_id)
        self.log.debug("(after creation snapshot_image manifests) List of pools: {0}".format(stage_after_create_snapshot_image['pools']))
        self.log.debug("(after creation snapshot_image manifests) List of volumes: {0}".format(stage_after_create_snapshot_image['volumes']))
        self.log.debug("(after creation snapshot_image manifests) List of thin volumes: {0}".format(stage_after_create_snapshot_image['thin_volumes']))
        self.log.debug("(after creation snapshot_image manifests) List of snapshot groups: {0}".format(stage_after_create_snapshot_image['snapshot_groups_for_print']))
        self.log.debug("(after creation snapshot_image manifests) List of snapshot images: {0}".format(stage_after_create_snapshot_image['snapshots_for_print']))

        # Get snapshot image ID
        image_id = None
        for i in set(stage_after_create_snapshot_image['snapshots']) - set(stage_on_start['snapshots']):
            tmp = stage_after_create_snapshot_image['snapshots_for_assertion'][i]
            if tmp['group'] == sg['snapshot_group_id'] and tmp['volume'] == v['volume_id']:
                image_id = i

        # Constructing  custom site.pp and switching on it (CREATE SNAPSHOT VOLUME)
        sv = dict(snapshot_volume_id='BANANA_SNAPSHOT_VOLUME_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id,
                  pool_id=p['pool_id'],
                  image_id=image_id,
                  viewmode='readWrite',
                  repositorysize='10',
                  fullthreshold='14',
                  )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_snapshot_volume_section.format(**sv) +
                                                 'Netapp_e_storage_system <| |> -> Netapp_e_storage_pool <| |> -> Netapp_e_snapshot_volume <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_create_snapshot_volume = self.get_system_state(self.first_system_id)
        self.log.debug("(after creation snapshot_volume manifests) List of pools: {0}".format(stage_after_create_snapshot_volume['pools']))
        self.log.debug("(after creation snapshot_volume manifests) List of volumes: {0}".format(stage_after_create_snapshot_volume['volumes']))
        self.log.debug("(after creation snapshot_volume manifests) List of thin volumes: {0}".format(stage_after_create_snapshot_volume['thin_volumes']))
        self.log.debug("(after creation snapshot_volume manifests) List of snapshot groups: {0}".format(stage_after_create_snapshot_volume['snapshot_groups_for_print']))
        self.log.debug("(after creation snapshot_volume manifests) List of snapshot images: {0}".format(stage_after_create_snapshot_volume['snapshots_for_print']))
        self.log.debug("(after creation snapshot_volume manifests) List of snapshot volumes: {0}".format(stage_after_create_snapshot_volume['snapshot_volumes']))

        # Constructing  custom site.pp and switching on it (DELETE SNAPSHOT VOLUME)
        sv['ensure'] = 'absent'
        p['ensure'] = 'absent'
        sg['ensure'] = 'absent'
        v['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_snapshot_group_section.format(**sg) +
                                                 self.manifest_storage_snapshot_volume_section.format(**sv) +
                                                 'Netapp_e_snapshot_volume  <| |> -> Netapp_e_snapshot_group <| |> -> Netapp_e_volume <| |> ->  Netapp_e_storage_pool <| |>  -> Netapp_e_storage_system <| |>')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'require')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_delete_snapshot_volume = self.get_system_state(self.first_system_id)
        self.log.debug("(after deletion snapshot_volume manifests) List of pools: {0}".format(stage_after_delete_snapshot_volume['pools']))
        self.log.debug("(after deletion snapshot_volume manifests) List of volumes: {0}".format(stage_after_delete_snapshot_volume['volumes']))
        self.log.debug("(after deletion snapshot_volume manifests) List of thin volumes: {0}".format(stage_after_delete_snapshot_volume['thin_volumes']))
        self.log.debug("(after deletion snapshot_volume manifests) List of snapshot groups: {0}".format(stage_after_delete_snapshot_volume['snapshot_groups_for_print']))
        self.log.debug("(after deletion snapshot_volume manifests) List of snapshot images: {0}".format(stage_after_delete_snapshot_volume['snapshots_for_print']))
        self.log.debug("(after deletion snapshot_volume manifests) List of snapshot volumes: {0}".format(stage_after_delete_snapshot_volume['snapshot_volumes']))

        self.remove_BANANA_objects_by_REST(self.first_system_id)

        #Assertions
        assert 'BANANA_SNAPSHOT_VOLUME_{0}'.format(rand_hash) in stage_after_create_snapshot_volume['snapshot_volumes'] and \
               'BANANA_SNAPSHOT_VOLUME_{0}'.format(rand_hash) not in stage_after_delete_snapshot_volume['snapshot_volumes']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_map_create_delete(self):

        # Preparation and cleaning up of storage
        self.restore_first_system_by_REST()
        self.remove_BANANA_objects_by_REST(self.first_system_id)

        # Saving starting stage
        stage_on_start = self.get_system_state(self.first_system_id)

        self.log.debug("Current systems (before test): {0}".format(stage_on_start['storage_systems']))
        self.log.debug("(before manifests) List of pools: {0}".format(stage_on_start['pools']))
        self.log.debug("(before manifests) List of volumes: {0}".format(stage_on_start['volumes']))
        self.log.debug("(before manifests) List of thin volumes: {0}".format(stage_on_start['thin_volumes']))
        self.log.debug("(before manifests) List of snapshot groups: {0}".format(stage_on_start['snapshot_groups_for_print']))
        self.log.debug("(before manifests) List of snapshot images: {0}".format(stage_on_start['snapshots_for_print']))
        self.log.debug("(before manifests) List of maps(LUN): {0}".format(stage_on_start['volume_mappings']))

        # Constructing  custom site.pp and switching on it
        free_disks = self.get_free_disk(self.first_system_id, number=2)
        self.log.debug("Select free disks on '{1}': {0}".format(free_disks, self.first_system_id))
        rand_hash = hex(random.getrandbits(24))[2:-1]
        s = self.construct_dict_for_first_system('WATERMARK_{0}_{{0}}'.format(self.case_short_name(self.id())),
                                                 rand_hash)
        p = dict(pool_id='BANANA_POOL_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 raidlevel='raid0',
                 diskids="{0}".format(free_disks))
        v = dict(volume_id='BANANA_VOLUME_ONE_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 size='3',
                 pool_id=p['pool_id'],
                 sizeunit='gb',
                 segsize='512',
                 thin='false')
        port_types = [ 'iscsi', ]# ['notImplemented', 'scsi', 'fc', 'sata', 'sas', 'iscsi', 'ib', 'fcoe', '__UNDEFINED']
        port = "{{type => '{type}', port => '{port}', label => '{label}'}}".format(type=random.choice(port_types),
                                                                                   port='iqn.1998-05.com.osx:cd1234abcdef',
                                                                                   label='BANANA_PORT_ONE_{0}'.format(rand_hash))
        hg = dict(hostgroup_id='BANANA_HOSTGROUP_{0}'.format(rand_hash),
                  ensure='present',
                  system_id=self.first_system_id)
        h = dict(host_id='BANANA_HOST_{0}'.format(rand_hash),
                 ensure='present',
                 typeindex=random.choice([i['index'] for i in generic_get('host_types', array_id=self.first_system_id)]),
                 system_id=self.first_system_id,
                 hostgroup_id=hg['hostgroup_id'],
                 ports="[{0},]".format(port))
        m = dict(map_id='BANANA_MAP_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 source_id=v['volume_id'],
                 target_id=h['host_id'],
                 lun='10',
                 type='host')

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_storage_system_section.format(**s) +
                                                 self.manifest_storage_pool_section.format(**p) +
                                                 self.manifest_storage_volume_section.format(**v) +
                                                 self.manifest_storage_hostgroup_section.format(**hg) +
                                                 self.manifest_storage_host_section.format(**h) +
                                                 self.manifest_storage_map_section.format(**m) +
                                                 'Netapp_e_storage_pool <| |> -> Netapp_e_volume <| |> -> Netapp_e_host_group <| |>  -> Netapp_e_host <| |> -> Netapp_e_map <| |>')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        stage_after_create_map = self.get_system_state(self.first_system_id)
        self.log.debug("(after creation map manifests) List of pools: {0}".format(stage_after_create_map['pools']))
        self.log.debug("(after creation map manifests) List of volumes: {0}".format(stage_after_create_map['volumes']))
        self.log.debug("(after creation map manifests) List of thin volumes: {0}".format(stage_after_create_map['thin_volumes']))
        self.log.debug("(after creation map manifests) List of snapshot groups: {0}".format(stage_after_create_map['snapshot_groups_for_print']))
        self.log.debug("(after creation map manifests) List of snapshot images: {0}".format(stage_after_create_map['snapshots_for_print']))
        self.log.debug("(after creation map manifests) List of maps(LUN): {0}".format(stage_after_create_map['volume_mappings']))


        self.remove_BANANA_objects_by_REST(self.first_system_id)

        #Assertions
        assert True

#####################################################################################################################
    
    #@unittest2.skip('')
    def test_netapp_consistency_group_create_delete(self):
        """
        Test of netapp_consistency_group creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to create CG-GROUP consistency group by manifest
        3. Select by REST this CG-GROUP consistency group
        4. Delete this CG-GROUP
        5. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()

        assert self.first_system_id in stage_on_start

        cg_list_before = [j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)]
        self.log.debug("Current systems (before test): {systems}".format(systems=stage_on_start))
        self.log.debug("(before manifests) List of consistency group: {0}".format(cg_list_before))
        
        # Constructing  custom site.pp and switching on it
        rand_hash = hex(random.getrandbits(24))[2:-1]
        cg = dict(cg_id='BANANA_CG-GROUP_{0}'.format(rand_hash),
                 ensure='present',
                 system_id=self.first_system_id,
                 full_threshold=10,
                 auto_threshold=30,
                 repositoryfullpolicy='failbasewrites',
                 rollbackpriority='low',)
        
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_section.format(**cg))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()
        
        cg_list_after_create = [j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)]
        self.log.debug("(after creating manifest) List of consistency group: {0}".format(cg_list_after_create))
        
        
        cg['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_section.format(**cg))
        # Remove redundant params
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'full_threshold')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'auto_threshold')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'repositoryfullpolicy')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'rollbackpriority')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cg_list_after_delete = [j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)]
        self.log.debug("(after deleting manifest) List of consistency group: {0}".format(cg_list_after_delete))
        
        
        assert cg['cg_id'] in cg_list_after_create and cg['cg_id'] not in cg_list_after_delete

#####################################################################################################################
    
    #@unittest2.skip('')
    def test_netapp_consistency_group_update(self):
        """
        Test of netapp_consistency_group creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to update CG-GROUP consistency group by manifest
        3. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()

        assert self.first_system_id in stage_on_start

        # Constructing  custom site.pp and switching on it
        cg = dict(cg_id='BANANA_CG-GROUP_2be54e',
                 ensure='present',
                 system_id=self.first_system_id,
                 full_threshold=10,
                 auto_threshold=20,
                 repositoryfullpolicy='failbasewrites',
                 rollbackpriority='low',)

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,id=c_groups[cg['cg_id']])

        cg_list_before = generic_get('cgroup', **params)
        self.log.debug("(before manifests) List of consistency group: {0}".format(cg_list_before))
        
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_section.format(**cg))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cg_list_after_update = generic_get('cgroup', **params)
        self.log.debug("(after creating manifest) List of consistency group: {0}".format(cg_list_after_update))

        assert cg_list_before['id']==cg_list_after_update['id'] and cg['full_threshold']==cg_list_after_update['fullWarnThreshold'] and cg['auto_threshold']==cg_list_after_update['autoDeleteLimit'] and cg['repositoryfullpolicy']==cg_list_after_update['repFullPolicy'] and cg['rollbackpriority']==cg_list_after_update['rollbackPriority']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_consistency_group_member_volume_create_delete(self):
        """
        Test of netapp_consistency_group creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the consistency group is present on storage (if no, fail test case)
        3. Check if the repository pool is present on storage (if no, fail test case)
        4. Check if the volumes is present on storage (if no, fail test case)
        5. Make custom manifest to add consistency group member volume by manifest
        6. Select by REST this consistency group member volume
        7. Remove this volume from consistency group 
        8. Watch errors
        """

        system_status = dict(storage_systems=self.get_system_list(),
                            cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            pools=[j['label'] for j in generic_get('pools', array_id=self.first_system_id)],
                            volumes=[j['name'] for j in generic_get('volumes', array_id=self.first_system_id)],
                            thin_volumes=[j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)],)
        
        # Constructing  custom site.pp and switching on it
        cg_vol = dict(vol_id='CG-03',
                       ensure='present',
                       system_id=self.first_system_id,
                       cg_id='BANANA_CG-GROUP_2be54e',
                       pool_id='Disk_Pool_1',
                       scanmedia='true',
                       validateparity='true',
                       repositorypercent=10,)
        
        #Fail if system_id or cg_id or pool_id not found in system          
        assert cg_vol['system_id'] in system_status['storage_systems'] and cg_vol['cg_id'] in system_status['cgroups'] and cg_vol['pool_id'] in system_status['pools']

        #Fail if volume not found in volume/thin volume in system
        assert cg_vol['vol_id'] in system_status['volumes'] or cg_vol['vol_id'] in system_status['thin_volumes']

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,cgId=c_groups[cg_vol['cg_id']])

        cg_vol_list_before = [j['baseVolumeName'] for j in generic_get('cgMembers', **params)]
        self.log.debug("(before manifests) List of members in consistency group: {0}".format(cg_vol_list_before))

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_member_volume_section.format(**cg_vol))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cg_vol_list_after_create = [j['baseVolumeName'] for j in generic_get('cgMembers', **params)]
        self.log.debug("(after creating manifest) List of members in consistency group: {0}".format(cg_vol_list_after_create))

        #Remove Volume from Group
        cg_vol['ensure'] = 'absent'
        #cg_vol['retainrepositories'] = 'true'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_member_volume_section.format(**cg_vol))
        # Remove redundant params
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'pool_id')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'scanmedia')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'validateparity')
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'repositorypercent')
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cg_vol_list_after_delete = [j['baseVolumeName'] for j in generic_get('cgMembers', **params)]
        self.log.debug("(after deleting manifest) List of members in consistency group: {0}".format(cg_vol_list_after_delete))
        
        assert cg_vol['vol_id'] in cg_vol_list_after_create and cg_vol['vol_id'] not in cg_vol_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_consistency_group_multiple_member_volume_add(self):
        """
        Test of netapp_consistency_group creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the consistency group is present on storage (if no, fail test case)
        3. Check if all repository pool is present on storage (if no, fail test case)
        4. Check if all volumes is present on storage (if no, fail test case)
        5. Make custom manifest to add consistency group member volumes by manifest 
        6. Watch errors
        """

        system_status = dict(storage_systems=self.get_system_list(),
                            cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            pools=[j['label'] for j in generic_get('pools', array_id=self.first_system_id)],
                            volumes=[j['name'] for j in generic_get('volumes', array_id=self.first_system_id)],
                            thin_volumes=[j['name'] for j in generic_get('thin_volumes', array_id=self.first_system_id)],)

        # Constructing  custom site.pp and switching on it
        vol_to_add = ['CG-03','CG-02']

        volume1 = "{{ volume=>'{vol_id}',repositorypool=>'{pool_id}',scanmedia=>{scanmedia},validateparity=>{validateparity},repositorypercent => {repositorypercent}}}".format(
            vol_id=vol_to_add[0],
            pool_id='Disk_Pool_1',
            scanmedia='true',
            validateparity='true',
            repositorypercent=10)

        volume2 = "{{ volume=>'{vol_id}',repositorypool=>'{pool_id}'}}".format(
            vol_id=vol_to_add[1],
            pool_id='Disk_Pool_1')

        volumes = "[{0},\n\t\t\t {1}]".format(volume1, volume2)
        multi_mem = dict(system_id=self.first_system_id,
                        cg_id='BANANA_CG-GROUP_2be54e',
                        volumes=volumes)

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,cgId=c_groups[multi_mem['cg_id']])

        cg_vol_list_before = [j['baseVolumeName'] for j in generic_get('cgMembers', **params)]
        self.log.debug("(before manifests) List of members in consistency group: {0}".format(cg_vol_list_before))

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_multiple_member_volume_section.format(**multi_mem))
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cg_vol_list_after_create = [j['baseVolumeName'] for j in generic_get('cgMembers', **params)]
        self.log.debug("(after creating manifest) List of members in consistency group: {0}".format(cg_vol_list_after_create))

        assert all(x in cg_vol_list_after_create for x in vol_to_add)

#####################################################################################################################
    
    #@unittest2.skip('')
    def test_netapp_consistency_group_snapshot_create_delete(self):
        """
        Test of netapp_consistency_group snapshot creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to create consistency group snapshot by manifest
        3. Select by REST this consistency group snapshot
        4. Delete this consistency group member
        5. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        #self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        cgsnapshot = dict(consistencygroup='CG_Test_SP2',
                 ensure='present',
                 system_id=self.first_system_id,
                 )
        
        system_status = dict(storage_systems=self.get_system_list(),
                             cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            )

        #Fail if system_id or cg_id not found in system          
        assert cgsnapshot['system_id'] in system_status['storage_systems'] and cgsnapshot['consistencygroup'] in system_status['cgroups'] 

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_section.format(**cgsnapshot))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,cgId=c_groups[cgsnapshot['consistencygroup']])
        self.log.debug("(params) {0}".format(params))
        
        cgsnapshot_list_after_create = [j['pitSequenceNumber'] for j in generic_get('cgSnapshots', **params)]
        self.log.debug("(after creating manifest) List of consistency group snapshots: {0}".format(cgsnapshot_list_after_create))
        
        cgsnapshot['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_section.format(**cgsnapshot))
        self.switch_to_custom_manifest(new_site_pp)

        # # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cgsnapshot_list_after_delete = [j['pitSequenceNumber'] for j in generic_get('cgSnapshots', **params)]
        self.log.debug("(after deleting manifest) List of consistency group snapshots: {0}".format(cgsnapshot_list_after_delete))

        assert True

#####################################################################################################################
    
    #@unittest2.skip('')
    def test_netapp_consistency_group_snapshot_rollback(self):
        """
        Test of netapp_consistency_group snapshot rollback opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to rollback consistency group snapshot by manifest
        3. Select by REST this consistency group snapshot
        4. Rollback this consistency group member
        5. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        assert self.first_system_id in stage_on_start
        
        cgsnapshot = dict(consistencygroup='CG_Test_SP2',
                 snapshotnumber=143,
                 system_id=self.first_system_id,
                 )
        
        system_status = dict(storage_systems=self.get_system_list(),
                             cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            )

        #Fail if system_id or cg_id not found in system          
        assert cgsnapshot['system_id'] in system_status['storage_systems'] and cgsnapshot['consistencygroup'] in system_status['cgroups'] 

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_rollback_section.format(**cgsnapshot))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        assert True

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_consistency_group_snapshot_view_create_delete_by_snapshot(self):
        """
        Test of netapp_consistency_group snapshot view creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to create consistency group snapshot view by manifest
        3. Select by REST this consistency group snapshot view 
        4. Delete this consistency group view
        5. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        assert self.first_system_id in stage_on_start
        
        cgsnapshot_view = dict(consistencygroup='CG_Test_SP2',
                 ensure='present',
                 system_id=self.first_system_id,
                 snapshotnumber=143,
                 viewname = 'v123',
                 viewtype = 'bySnapshot',
                 validateparity = 'false',
                 )
        
        system_status = dict(storage_systems=self.get_system_list(),
                             cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            )

        #Fail if system_id or cg_id not found in system          
        assert cgsnapshot_view['system_id'] in system_status['storage_systems'] and cgsnapshot_view['consistencygroup'] in system_status['cgroups'] 

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_view_by_snapshot_section.format(**cgsnapshot_view))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,cgId=c_groups[cgsnapshot_view['consistencygroup']])
        self.log.debug("(params) {0}".format(params))
        
        cgsnapshot_view_list_after_create = [j['label'] for j in generic_get('cgViews', **params)]
        self.log.debug("(after creating manifest) List of consistency group snapshots views: {0}".format(cgsnapshot_view_list_after_create))
        
        cgsnapshot_view['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_view_by_snapshot_section.format(**cgsnapshot_view))
        self.switch_to_custom_manifest(new_site_pp)

        # # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cgsnapshot_view_list_after_delete = [j['label'] for j in generic_get('cgViews', **params)]
        self.log.debug("(after deleting manifest) List of consistency group snapshots views: {0}".format(cgsnapshot_view_list_after_delete))

        assert cgsnapshot_view['viewname'] in cgsnapshot_view_list_after_create and cgsnapshot_view['viewname'] not in cgsnapshot_view_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_consistency_group_snapshot_view_create_delete_by_volume(self):
        """
        Test of netapp_consistency_group snapshot view creation and delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to create consistency group snapshot view by manifest
        3. Select by REST this consistency group snapshot view 
        4. Delete this consistency group view
        5. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        assert self.first_system_id in stage_on_start
        
        cgsnapshot_view = dict(consistencygroup='CG_Test_SP2',
                 ensure='present',
                 system_id=self.first_system_id,
                 snapshotnumber=143,
                 viewname = 'v12',
                 viewtype = 'byVolume',
                 volume   = 'thin_vol',
                 validateparity = 'false',
                 )
        
        system_status = dict(storage_systems=self.get_system_list(),
                             cgroups=[j['label'] for j in generic_get('cgroups', array_id=self.first_system_id)],
                            )

        #Fail if system_id or cg_id not found in system          
        assert cgsnapshot_view['system_id'] in system_status['storage_systems'] and cgsnapshot_view['consistencygroup'] in system_status['cgroups'] 

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_view_by_volume_section.format(**cgsnapshot_view))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        #Get consistency group id from group name
        c_groups = dict((c_group['label'],c_group['id']) for c_group in generic_get('cgroups', array_id=self.first_system_id))
        params=dict(array_id=self.first_system_id,cgId=c_groups[cgsnapshot_view['consistencygroup']])
        self.log.debug("(params) {0}".format(params))
        
        cgsnapshot_view_list_after_create = [j['label'] for j in generic_get('cgViews', **params)]
        self.log.debug("(after creating manifest) List of consistency group snapshots views: {0}".format(cgsnapshot_view_list_after_create))
        
        cgsnapshot_view['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_consistency_group_snapshot_view_by_volume_section.format(**cgsnapshot_view))
        self.switch_to_custom_manifest(new_site_pp)

        # # Run 'puppet device' by subprocess
        self.run_puppet_device()

        cgsnapshot_view_list_after_delete = [j['label'] for j in generic_get('cgViews', **params)]
        self.log.debug("(after deleting manifest) List of consistency group snapshots views: {0}".format(cgsnapshot_view_list_after_delete))

        assert cgsnapshot_view['viewname'] in cgsnapshot_view_list_after_create and cgsnapshot_view['viewname'] not in cgsnapshot_view_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_web_proxy_upgrade(self):
        """
        Test of netapp_web_proxy_upgrade upgrade opertion.

        1. Check current version of web proxy service
        2. Download latest given version from server
        3. Check current version before executing manifest and after executing manifest
        4. Watch errors
        """

        web_proxy_version_before = generic_get('web_proxy')
        self.log.debug("(before creating manifest) current version of web proxy: {0}".format(web_proxy_version_before['currentVersions'][0]['version']))

        req = dict(ensure='upgraded',force='true',)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_web_proxy_upgrade.format(**req))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()
        
        web_proxy_version_after = generic_get('web_proxy')
        self.log.debug("(after creating manifest) current version of web proxy: {0}".format(web_proxy_version_after['currentVersions'][0]['version']))

        assert web_proxy_version_before['currentVersions'][0]['version'] != web_proxy_version_after['currentVersions'][0]['version']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_web_proxy_stage_activate(self):
        """
        Test of netapp_web_proxy_upgrade upgrade opertion.

        1. Check current version of web proxy service
        2. Download latest given version from server
        3. Check staged version and current version are different after staged new version
        4. Activate new version
        5. Check current version before stage version and after activate new version
        6. Watch errors
        """

        web_proxy_version_before = generic_get('web_proxy')
        self.log.debug("(before creating manifest) current version of web proxy: {0}".format(web_proxy_version_before['currentVersions'][0]['version']))

        req = dict(ensure='staged',force='true',)
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_web_proxy_upgrade.format(**req))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()
        
        web_proxy_version_after = generic_get('web_proxy')
        self.log.debug("(after staged new version) current version of web proxy: {0}".format(web_proxy_version_after['currentVersions'][0]['version']))

        assert web_proxy_version_after['currentVersions'][0]['version'] != web_proxy_version_after['stagedVersions'][0]['version']

        req['ensure'] = 'activated'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_web_proxy_upgrade.format(**req))
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'force') # Remove not require params
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        web_proxy_version_after_activate = generic_get('web_proxy')
        self.log.debug("(after activate new version) current version of web proxy: {0}".format(web_proxy_version_after_activate['currentVersions'][0]['version']))

        assert web_proxy_version_before['currentVersions'][0]['version'] != web_proxy_version_after_activate['currentVersions'][0]['version']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_firmware_file(self):
        '''
        Test of netapp_firmware_file upload and delete from server

        1. Upload new firmware file 
        2. Check given file uploaded to server or not
        3. Delete firmware file
        4. Check file was destroyed on server or not
        5. Watch errors

        '''
        before_file_list = [j['filename'] for j in generic_get('firmware-cfw-file')]
        self.log.debug("(before creating manifest) List of firmware file: {0}".format(before_file_list))

        files = dict(ensure='present',
                    filename='RC_08201100_e10_820_5468.dlp',
                    folderlocation='/root',
                    validatefile='true',
                    )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()
        
        file_list_after_create = [j['filename'] for j in generic_get('firmware-cfw-file')]
        self.log.debug("(after creating manifest) List of firmware file: {0}".format(file_list_after_create))

        files['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        # Remove not require params
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'folderlocation') 
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'validatefile') 
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        file_list_after_delete = [j['filename'] for j in generic_get('firmware-cfw-file')]
        self.log.debug("(after deletion manifest) List of firmware file: {0}".format(file_list_after_delete))

        assert files['filename'] in file_list_after_create and files['filename'] not in file_list_after_delete

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_firmware_upgrade(self):
        '''
        Test of netapp_firmware_upgrade upgrade opertion.

        1. Upload new firmware file to upgrade firmware
        2. Upgrade firmware with latest given version
        3. Check firmware upgrade successfully
        4. Delete uploaded firmware file on server
        5. Watch errors

        '''

        firmware_file_name = 'RC_08201100_e10_820_5468.dlp'
        firmware_file_type = 'cfwfile'  #'cfwfile','nvsramfile'

        #Upload new firmware file to server
        files = dict(ensure='present',
                    filename=firmware_file_name,
                    folderlocation='/root',
                    validatefile='true',
                    )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        self.switch_to_custom_manifest(new_site_pp)
        self.run_puppet_device()

        #Get current version of firmware before upgrading firmware
        before_fw_version = generic_get('storage-system', array_id=self.first_system_id)
        if firmware_file_type == 'cfwfile':
            self.log.debug("(before manifests) Current version of firmware: {0}".format(before_fw_version['fwVersion']))
        else:
            self.log.debug("(before manifests) Current version of NVSRAM: {0}".format(before_fw_version['nvsramVersion']))

        #Upgrade firmware
        upgrade = dict(ensure='upgraded',
                    filename=firmware_file_name,
                    system_id=self.first_system_id,
                    firmwaretype=firmware_file_type,
                    melcheck='true',
                    compatibilitycheck='true',
                    releasedbuildonly='true',
                    waitforcompletion='true',
                    )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_upgrade.format(**upgrade))
        self.switch_to_custom_manifest(new_site_pp)
        self.run_puppet_device()

        #Get current version of firmware after upgrading firmware
        after_fw_version = generic_get('storage-system', array_id=self.first_system_id)
        if firmware_file_type == 'cfwfile':
            self.log.debug("(after manifests) Current version of firmware: {0}".format(after_fw_version['fwVersion']))
        else:
            self.log.debug("(after manifests) Current version of NVSRAM: {0}".format(after_fw_version['nvsramVersion']))

        #Delete uploded firmware file to server
        files['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'folderlocation') 
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'validatefile') 
        self.switch_to_custom_manifest(new_site_pp)
        self.run_puppet_device()

        if firmware_file_type == 'cfwfile':
            assert before_fw_version['fwVersion'] != after_fw_version['fwVersion']
        else:
            assert before_fw_version['nvsramVersion'] != after_fw_version['nvsramVersion']

#####################################################################################################################

    #@unittest2.skip('')
    def test_netapp_firmware_stage_activate(self):
        '''
        Test of netapp_firmware_upgrade upgrade opertion.

        1. Upload new firmware file to upgrade firmware
        2. Stage new version of firmware
        3. Check new version staged successfully
        4. Activate firmware staged version
        5. Check current updated version of firmware after activation
        6. Watch errors

        '''
        firmware_file_name = 'RC_08200300_e10_820_5468.dlp'

        #Upload new firmware file to server
        files = dict(ensure='present',
                    filename=firmware_file_name,
                    folderlocation='/root',
                    validatefile='true',
                    )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        self.switch_to_custom_manifest(new_site_pp)
        self.run_puppet_device()

        #Staged firmware
        firmware_dict = dict(ensure='staged',
                    filename=firmware_file_name,
                    system_id=self.first_system_id,
                    firmwaretype='cfwfile',
                    melcheck='true',
                    compatibilitycheck='true',
                    releasedbuildonly='true',
                    waitforcompletion='true',
                    )
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_upgrade.format(**firmware_dict))
        self.switch_to_custom_manifest(new_site_pp)
        
         # Run 'puppet device' by subprocess
        self.run_puppet_device()

        #Get stage version of firmware after stage firmware
        after_fw_stage = generic_get('storage-system-graph', array_id=self.first_system_id)
        stage_fw = after_fw_stage['sa']['stagedFirmware']
        self.log.debug("(after manifests) Current staged version of firmware: {0}".format(stage_fw['fwVersion']))

        #Activate firmware version
        firmware_dict['ensure'] = 'activated'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_upgrade.format(**firmware_dict))
        # Remove not require params 
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'compatibilitycheck') 
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'releasedbuildonly') 
        self.switch_to_custom_manifest(new_site_pp)

        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        #Get current version of firmware after upgrading firmware
        after_fw_activate = generic_get('storage-system', array_id=self.first_system_id)
        self.log.debug("(after manifests) Current activated version of firmware: {0}".format(after_fw_activate['fwVersion']))

        #Delete uploded firmware file to server
        files['ensure'] = 'absent'
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_firmware_file.format(**files))
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'folderlocation') 
        new_site_pp = self.remove_line_from_multiline_regexp(new_site_pp, 'validatefile') 
        self.switch_to_custom_manifest(new_site_pp)
        self.run_puppet_device()

        assert stage_fw['fwVersion'] == after_fw_activate['fwVersion']

#####################################################################################################################
    #@unittest2.skip('')
    def test_netapp_flash_cache_create(self):
        """
        Test of netapp_flash_cache flash cache creation opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Make custom manifest to create flash Cache by manifest
        3. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        flashCache = dict(cachename='SSD_SP4',
                 ensure='created',
                 system_id=self.first_system_id,
                 enableexistingvolumes='false',
                 diskids=["010000005001E8200002D1A80000000000000000"]
                 )


        for i in flashCache['diskids']:
            params=dict(array_id=self.first_system_id,id=i)
            self.log.debug("(params) {0}".format(params))
            drvs=generic_get('drive', **params)
            assert i == drvs['id']
      
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_create_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        assert flashCache['cachename'] == flash_cache['flashCacheBase']['label']

#####################################################################################################################
    #@unittest2.skip('')
    def test_netapp_flash_cache_suspend_resume(self):
        """
        Test of netapp_flash_cache flash cache suspend and resume opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the flash cache is present(if no, fail test case)
        3. Make custom manifest to suspend and resume flash Cache by manifest
        4. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        flashCache = dict(cachename='SSD_SP4',
                 ensure='suspended',
                 system_id=self.first_system_id,
                 ignorestate='false'
                 )

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_suspend_resume_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        assert flashCache['ensure'] == flash_cache['flashCacheBase']['status']

        flashCache = dict(cachename='SSD_SP4',
                 ensure='resumed',
                 system_id=self.first_system_id,
                 ignorestate='false'
                 )

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_suspend_resume_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        assert "optimal" == flash_cache['flashCacheBase']['status']

#####################################################################################################################
    #@unittest2.skip('')
    def test_netapp_flash_cache_update(self):
        """
        Test of netapp_flash_cache flash cache update opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the flash cache is present(if no, fail test case)
        3. Make custom manifest to update flash cache by manifest
        4. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        flashCache = dict(cachename='SSD_SP4',
                 ensure='updated',
                 system_id=self.first_system_id,
                 newname='SSD_SP1',
                 configtype='multimedia',
                 )

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        self.log.debug("(params) {0}".format(flash_cache))
        assert flashCache['cachename'] == flash_cache['flashCacheBase']['label']
         
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_update_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        self.log.debug("(params) {0}".format(flash_cache))
        assert flashCache['newname'] == flash_cache['flashCacheBase']['label'] and flashCache['configtype'] == flash_cache['flashCacheBase']['configType']

#####################################################################################################################
    #@unittest2.skip('')
    def test_netapp_flash_cache_delete(self):
        """
        Test of netapp_flash_cache flash cache delete opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the flash cache is present(if no, fail test case)
        3. Make custom manifest to delete flash cache by manifest
        4. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        flashCache = dict(cachename='SSD_SP4',
                 ensure='deleted',
                 system_id=self.first_system_id,
                 )

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        self.log.debug("(params) {0}".format(flash_cache))
        assert flashCache['cachename'] == flash_cache['flashCacheBase']['label']
         
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_delete_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        assert True

#####################################################################################################################
    #@unittest2.skip('')
    def test_netapp_flash_cache_drives_add_remove(self):
        """
        Test of test_netapp_flash_cache_drives_add_remove flash cache add and remove drives opertion.

        1. Check if the first system is present on storage (if no, fail test case)
        2. Check if the flash cache is present(if no, fail test case)
        3. Make custom manifest to add and remove flash cache drives by manifest
        4. Watch errors
        """
        
        # Saving starting stage
        stage_on_start = self.get_system_list()
        self.log.debug("(stage_on_start) {0}".format(stage_on_start))
        assert self.first_system_id in stage_on_start
        
        flashCache = dict(cachename='SSD_SP4',
                 ensure='present',
                 system_id=self.first_system_id,
                 diskids=["010000005001E8200002D1A80000000000000000"]
                 )

        flash_cache = generic_get('flashCache', array_id=self.first_system_id)
        self.log.debug("(params) {0}".format(flash_cache))
        assert flashCache['cachename'] == flash_cache['flashCacheBase']['label']
        assert flash_cache['flashCacheBase']['status'] == "optimal"

        for i in flashCache['diskids']:
            params=dict(array_id=self.first_system_id,id=i)
            self.log.debug("(params) {0}".format(params))
            drvs=generic_get('drive', **params)
            assert i == drvs['id']
         
        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_drive_add_remove_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        flashCache = dict(cachename='SSD_SP4',
                 ensure='absent',
                 system_id=self.first_system_id,
                 diskids=["010000005001E8200002D1A80000000000000000"]
                 )

        new_site_pp = self.manifest_frame.format(inner_sections=self.manifest_flash_cache_drive_add_remove_section.format(**flashCache))
        self.switch_to_custom_manifest(new_site_pp)
        
        # Run 'puppet device' by subprocess
        self.run_puppet_device()

        assert True

##################################### HERE REAL TESTING HAS GONE !!! ################################################

if __name__ == '__main__':
    unittest2.main(verbosity=1)
