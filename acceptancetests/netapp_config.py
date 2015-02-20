import requests
from ConfigParser import SafeConfigParser

####################


config_file = SafeConfigParser({'host': 'http://localhost',
                                'port': '8080',
                                'userId': 'rw',
                                'password': 'rw',
                                'verbose_output': 'False'})
config_file.read('netapp_testsuite_options.conf')

manifest_path = config_file.get('puppet', 'manifest_path')

verbose_output = config_file.getboolean('tests', 'verbose_output')

# DUT parameters
first_system_id = config_file.get('tests', 'first_system_id')
first_system_ip1 = config_file.get('tests', 'first_system_ip1')
first_system_ip2 = config_file.get('tests', 'first_system_ip2')
first_system_pass = config_file.get('tests', 'first_system_pass')
first_system_test_pass = config_file.get('tests', 'first_system_test_pass')
first_system_test_ip =config_file.get('tests', 'first_system_test_ip')

second_system_id = config_file.get('tests', 'second_system_id')
second_system_ip1 = config_file.get('tests', 'second_system_ip1')
second_system_ip2 = config_file.get('tests', 'second_system_ip2')
second_system_pass = config_file.get('tests', 'second_system_pass')

#URL Parameters
server_root_url = '{0}:{1}'.format(config_file.get('netapp', 'host'), config_file.get('netapp', 'port'))
api_version = 2
api_path = '/devmgr/v{version}'.format(version=api_version)

#Specify username and password for the api here. User should have read/write access.
auth = (config_file.get('netapp', 'userId'), config_file.get('netapp', 'password'))

#Create a persistent session with the follow settings
session = requests.Session()
session.verify = False # False to not verify the SSL certificate, which is necessary with a self-signed certificate
session.auth = auth  # Configure the session to use HTTP Basic Auth
session.headers.update({'Content-type': 'application/json'}) #Input for PUT/POST is always json
session.headers.update({'Accept': 'application/json'}) #Always expect to receive a json response body

base_url = server_root_url + api_path


