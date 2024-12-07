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
    if 'method' not in params['data']:
        return False
    if 'src' not in params['data']:
        return False
    if 'params' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params {params}")
        return

    id=params['data']['src']

    device=iot_device.objects(context).select().where(iot_device.id==id).to_entity()
    if device==None:
        device=iot_device()
        device.id.value=id
        device.name.value=id
        device.address.value="0.0.0.0"
        device.vendor_id.value="shelly"
        device.insert(context)
    
    #device=iot_device.objects(context).select().where(iot_device.id==shelly_external_id)
    #if device==None:
    #    logger.warning(f"Device not found in iot_device {shelly_external_id}")
    #    return

