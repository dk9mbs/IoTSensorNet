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

    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params {params}")
        return

    wlan=None
    if 'params' in params['data']:
        if 'wifi' in params['data']['params']:
            wlan=params['data']['params']['wifi']

    if 'result' in params['data']:
        if 'wifi' in params['data']['result']:
            wlan=params['data']['result']['wifi']

    if wlan==None:
        logger.warning(f"Missing params or result {params}")
        return

    id=params['data']['src']
    address="0.0.0.0"
    wlan_rssi=0
    wlan_ssid=""

    address=wlan['sta_ip']
    wlan_rssi=wlan['rssi']
    wlan_ssid=wlan['ssid']

    device=iot_device.objects(context).select().where(iot_device.id==id).to_entity()
    if device==None:
        device=iot_device()
        device.id.value=id
        device.name.value=id
        device.address.value=address
        device.vendor_id.value="shelly"
        device.network_rssi.value=wlan_rssi
        device.network_ssid.value=wlan_ssid
        device.last_scan_on.value=datetime.datetime.now()
        device.insert(context)
    else:
        device.address.value=address
        device.network_rssi.value=wlan_rssi
        device.network_ssid.value=wlan_ssid
        device.last_scan_on.value=datetime.datetime.now()
        device.update(context)
        
