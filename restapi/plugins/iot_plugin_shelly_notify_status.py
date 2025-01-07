import datetime
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log
from shared.model import *
from services.mqtt_client import MqttClient

logger=log.create_logger(__name__)

def _validate(params):
    if 'data' not in params:
        return False
    if 'src' not in params['data']:
        return False
    if 'id' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params {params}")
        return

    src=params['data']['src']
    id=params['data']['id']

    device=iot_device.objects(context).select().where(iot_device.id==src).to_entity()
    if device==None:
        device=iot_device()
        device.id.value=src
        device.name.value=src
        device.vendor_id.value="shelly"
        device.insert(context)

    wlan=None
    version=None
    version_available=None

    if 'params' in params['data']:
        if 'wifi' in params['data']['params']:
            wlan=params['data']['params']['wifi']

    if 'result' in params['data']:
        if 'wifi' in params['data']['result']:
            wlan=params['data']['result']['wifi']
        
        if 'ver' in params['data']['result']:
            version=params['data']['result']['ver']

        if id=='Shelly.CheckForUpdate' and 'stable' in params['data']['result']:
            version_available=params['data']['result']['stable']['version']

    if version_available!=None:
        device.version_available.value=version_available
        device.last_scan_on.value=datetime.datetime.now()

    if version!=None:
        device.version.value=version
        device.last_scan_on.value=datetime.datetime.now()

    if wlan!=None:
        address="0.0.0.0"
        wlan_rssi=0
        wlan_ssid=""

        address=wlan['sta_ip']
        wlan_rssi=wlan['rssi']
        wlan_ssid=wlan['ssid']

        device.address.value=address
        device.network_rssi.value=wlan_rssi
        device.network_ssid.value=wlan_ssid
        device.last_scan_on.value=datetime.datetime.now()

    device.update(context)
        
