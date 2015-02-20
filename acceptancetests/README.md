Acceptance Tests
================

These tests are designed for testing of puppet Netapp E-series module. Puppet Netapp E-series module uses 'puppet device' ability, defines its own types and providers, and communicates with Netapp appliance via REST requests to Santricity Proxy Services.

REQUIREMENTS

- Python (Python 2.6.6)
- Working Proxy Services with correct settings (NetApp SANtricity Web Services Proxy 1.1, Builder Version:  01.10.x000.0002)
- Netapp E-series Storages with correct network settings
- Installed puppet (v. 3.7.4)
- Installed puppet Netapp E-series module

if CLI tool is available, it is possible to check storage by command:
SMcli <storage_ip> -c 'show storageArray;' -p <admin_pass>

WARNING! Puppet agent option 'usecacheonfailure' must be set to false (in puppet.conf, in [agent] section)

TESTS STRUCTURE

Testsuite's files:

netapp_testsuite.py - main file that contains all the tests
netapp_helper_class.py - file with helper function, manifests templates, setUpClass and tearDownClass methods
netapp_restlibs.py - REST functions and API-templates
netapp_config.py - config-file parsing
netapp_testsuite_options.conf.sample - sample of test-suite's config file

Testsuite is based on standard  python test library 'unittest'.
REST-functions are implemented using python library 'request'.
Also tests use common python libraries like 'os', 'subprocess', 'sh', 'random', 'time' and so on.

TESTS RUNNING

Test-suite allows to run specific tests or all tests.

Get list of tests:

nosetests -v --collect-only *suite*.py
(for human readable name of tests)
or
grep -e 'def test_' *suite*.py
(for pythonic name of tests)

Run all tests:

python netapp_testsuite.py
or
nosetests *suite*.py

Run specific test:

nosetests -v netapp_testsuite:NetApp_Puppet_Module_Test_Suite.test_netapp_snapshot_image_create_delete

Also other nosetests options can be used (at the time of writing of these tests nosetests version 1.3.4 was used)

TESTS DESCRIPTION

- All tests (except mirroring-oriented) are performed on the first storage from config-file
- At the beginning of each test-suite (or its parts) running original manifest site.pp is saved, and restored after tests are finished
- Tests preserve all entities on storage, that were created before tests running, and clean up all temporary entities created during tests execution
- Tests work in the following way: get state of storage via REST, construct custom manifest, apply it to puppet, get state via REST again, and compare states before with state after for test assertions
- Due to some puppet system limitations, there are 15sec delay between test cases


AUTHOR AND LICENSING

Apache License version 2.0
Denys Kravchenko, Mirantis
dkravchenko@mirantis.com

