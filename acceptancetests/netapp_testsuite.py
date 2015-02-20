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

##################################### HERE REAL TESTING HAS GONE !!! ################################################

if __name__ == '__main__':
    unittest2.main(verbosity=1)
