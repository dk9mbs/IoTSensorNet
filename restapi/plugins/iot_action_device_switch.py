import datetime
import requests
import json

import plugins.iot_action_gw
import plugins.iot_action_shelly_mqtt

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
from shared.model import *

logger=log.create_logger(__name__)

def __validate(params):
    if 'input' not in params:
        return False
    if 'session_id' not in params['input']:
        return False
    if 'command' not in params['input']:
        return False
    if 'value' not in params['input']:
        return False
    if 'device' not in params['input']:
        return False

    return True

def config():
    return {"raise_exception": True}

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params")
        return

    routing=iot_device_routing.objects(context).select().where(iot_device_routing.internal_device_id==params['input']['device']). \
        to_entity()

    if routing==None:
        raise Exception(f"Routing not found for device: {params['input']['device']}")
    device=iot_device.objects(context).select().where(iot_device.id==routing.external_device_id.value).to_entity()

    logger.info(f"Vendor: {device.vendor_id.value}")
    if device.vendor_id.value=='tuya':
        plugins.iot_action_gw.execute(context, plugin_context, params)
    elif device.vendor_id.value=='shelly':
        plugins.iot_action_shelly_mqtt.execute(context, plugin_context, params)

