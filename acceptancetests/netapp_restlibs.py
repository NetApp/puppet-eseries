from pprint import pprint
import time
import json
import contextlib
import requests
from netapp_config import base_url, session


#resource paths
resources = {
'storage-systems': '/storage-systems',
'storage-system': "/storage-systems/{array_id}",
'pools': "/storage-systems/{array_id}/storage-pools",
'pool': "/storage-systems/{array_id}/storage-pools/{id}",
'drives': "/storage-systems/{array_id}/drives",
'drive': "/storage-systems/{array_id}/drives/{id}",
'volumes': "/storage-systems/{array_id}/volumes",
'volume': "/storage-systems/{array_id}/volumes/{id}",
'thin_volumes' : "/storage-systems/{array_id}/thin-volumes",
'thin_volume' : "/storage-systems/{array_id}/thin-volumes/{id}",
'snapshot_groups': "/storage-systems/{array_id}/snapshot-groups",
'snapshot_group': "/storage-systems/{array_id}/snapshot-groups/{id}",
'snapshot_views': "/storage-systems/{array_id}/snapshot-volumes",
'snapshot_view': "/storage-systems/{array_id}/snapshot-volumes/{id}",
'snapshots': "/storage-systems/{array_id}/snapshot-images",
'snapshot': "/storage-systems/{array_id}/snapshot-images/{id}",
'volume_copies' : "/storage-systems/{array_id}/volume-copy-jobs",
'volume_copy' : "/storage-systems/{array_id}/volume-copy-jobs/{id}",
'volume_copy_control' : "/storage-systems/{array_id}/volume-copy-jobs-control/{id}",
'analysed_volume_statistics': "/storage-systems/{array_id}/analysed-volume-statistics",
'volume_statistics': "/storage-systems/{array_id}/volume-statistics",
'volume_statistic' : '/storage-systems/{array_id}/volume-statistics/{id}',
'analysed-drive_statistics': "/storage-systems/{array_id}/analysed-drive-statistics",
'drive_statistics': "/storage-systems/{array_id}/drive-statistics",
'drive_statistic' : '/storage-systems/{array_id}/drive-statistics/{id}',
'volume_mappings': "/storage-systems/{array_id}/volume-mappings",
'volume_mapping': "/storage-systems/{array_id}/volume-mappings/{id}",
'host_groups': '/storage-systems/{array_id}/host-groups',
'host_group': '/storage-systems/{array_id}/host-groups/{id}',
'hosts': '/storage-systems/{array_id}/hosts',
'host': '/storage-systems/{array_id}/hosts/{id}',
'host_ports' : '/storage-systems/{array_id}/host-ports',
'host_port' : '/storage-systems/{array_id}/host-ports/{id}',
'host_types' : '/storage-systems/{array_id}/host-types',
'events' : "/storage-systems/{array_id}/mel-events?count=8192",
'critical_events' : "/storage-systems/{array_id}/mel-events?critical=true",
'hardware' : "/storage-systems/{array_id}/hardware-inventory/",
'graph' : "/storage-systems/{array_id}/graph/",
'symbol': "/storage-systems/{array_id}/symbol/{command}/",
"cgroups" : "/storage-systems/{array_id}/consistency-groups",
"cgroup" : "/storage-systems/{array_id}/consistency-groups/{id}",
"cgView" : "/storage-systems/{array_id}/consistency-groups/{cgId}/views/{viewId}",
"cgMembers" : "/storage-systems/{array_id}/consistency-groups/{cgId}/member-volumes",
"cgMember" : "/storage-systems/{array_id}/consistency-groups/{cgId}/member-volumes/{volumeRef}",
"cgSnapshots" : "/storage-systems/{array_id}/consistency-groups/{cgId}/snapshots",
"cgSnapshot" : "/storage-systems/{array_id}/consistency-groups/{cgId}/snapshots/{sequenceNumber}",
"cgRollback" : "/storage-systems/{array_id}/consistency-groups/{cgId}/snapshots/{sequenceNumber}/rollback",
"cgViews" : "/storage-systems/{array_id}/consistency-groups/{cgId}/views",
"global_events" : "/events",
"async-mirrors" : "/storage-systems/{array_id}/async-mirrors",
"async-mirror" : "/storage-systems/{array_id}/async-mirrors/{id}",
"async-mirror-pairs" : "/storage-systems/{array_id}/async-mirrors/{mirror_id}/pairs",
"async-mirror-pair" : "/storage-systems/{array_id}/async-mirrors/{mirror_id}/pairs/{id}",
"async-mirror-progress" : "/storage-systems/{array_id}/async-mirrors/{id}/progress",
"async-mirror-resume" : "/storage-systems/{array_id}/async-mirrors/{id}/resume",
"async-mirror-role" : "/storage-systems/{array_id}/async-mirrors/{id}/role",
"async-mirror-suspend" : "/storage-systems/{array_id}/async-mirrors/{id}/suspend",
"async-mirror-sync" : "/storage-systems/{array_id}/async-mirrors/{id}/sync",
"async-mirror-test" : "/storage-systems/{array_id}/async-mirrors/{id}/test",
"async-mirror-targets" : "/storage-systems/{array_id}/async-mirrors/arvm-arrays",
"ethernet-interfaces":"/storage-systems/{array_id}/configuration/ethernet-interfaces",
"web_proxy":"/upgrade",
"firmware-cfw-file":"/firmware/cfw-files/",
"storage-system-graph":"/storage-systems/{array_id}/graph",
"flashCache":"/storage-systems/{array_id}/flash-cache"
}

class ArrayInaccessibleException(Exception):
    def __init__(self, message):
        super(Exception, ArrayInaccessibleException).__init__(self, message)
        self.message = message

class RestException(Exception):
    def __init__(self, status_code, message):
        super(Exception, RestException).__init__(self, message)
        self.message = message
        self.status_code = status_code
    def __str__(self):
        return "Bad status '{}': {}".format(self.status_code, self.message)



@contextlib.contextmanager
def array_controller(addresses, id=None, wwn=None, password=None, retries=10):

    postData = {'controllerAddresses' : addresses, 'wwn' : wwn, 'password' : password, "id" : id}
    array = generic_post('storage-systems', postData)
    try:
        for i in range(retries):
            array = generic_get('storage-system', array_id=array['id'])
            status = array['status']
            if(status == 'neverContacted'):
                time.sleep(5)
            else:
                break
        if(status == 'neverContacted' or status == 'inaccessible'):
            raise ArrayInaccessibleException("Unable to access array {}!".format(array['id']))
        yield array
    except Exception:
        raise

def generic_get (object_type, query_string=None, **params):
    """Performs a GET request on the provided object_type

    :param object_type  -- an object type from the resources listing in the configuration file
    :param params       -- keyword arguments (when required) to complete the URL
    :param query_string -- dict that specifies the query string arguments

    Returns: json

    """

    url = base_url + resources[object_type].format(**params)

    req = session.get(url, params=query_string)
    return handleResponse(req)

def generic_delete (object_type, query_string=None, **params):
    """Performs a DELETE request on the provided object_type

    :param object_type  -- an object type from the resources listing in the configuration file
    :param params       -- keyword arguments (when required) to complete the URL
    :param query_string -- dict that specifies the query string arguments

    RETURNS: Status code for the http request

    """

    url = base_url + resources[object_type].format(**params)
    req = session.delete(url, params=query_string)
    return handleResponse(req)

def generic_post (object_type, data, query_string=None, **params):
    """Performs a POST request on the provided object_type

    :param object_type  -- an object type from the resources listing in the configuration file
    :param data         -- parameters provided as a dict to create the object in question
    :param params       -- keyword arguments (when required) to complete the URL
    :param query_string -- dict that specifies the query string arguments

    RETURNS: json

    """

    url = base_url + resources[object_type].format(**params)

    req = session.post(url, data=json.dumps(data), params=query_string)
    return handleResponse(req)

def handleResponse(req):
    if(req.status_code >= 300):
        try:
            response = req.json()
            raise RestException(req.status_code, response)
        except ValueError:
            raise RestException(req.status_code, "")
    if(req.status_code == 204):
        return None
    return req.json()
