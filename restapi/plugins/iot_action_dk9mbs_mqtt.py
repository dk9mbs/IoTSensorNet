import datetime
import requests
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
from core.setting import Setting
from shared.model import *
from services.mqtt_client import MqttClient

from plugins.iot_common import IotLocation

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

    port=0
    now=datetime.datetime.now()
    #config=plugin_context['config']

    device_id=params['input']['device']
    command=params['input']['command']
    value=params['input']['value']
    session_id=params['input']['session_id']
    if 'port' in params['input']:
        port=params['input']['port']

    routing=iot_device_routing.objects(context).select().where(iot_device_routing.internal_device_id==device_id).to_entity()
    if routing==None:
        logger.error(f"Devicerouting not found: {device_id}")
        raise Exception(f"Devicerouting not found: {device_id}")

    device=iot_device.objects(context).select().where(iot_device.id==routing.external_device_id.value).to_entity()
    if device == None:
        logger.error(f"Device not found: {device_id}")
        raise Exception(f"Device not found: {device_id}")


    with MqttClient(context) as client:
        payload='{"id":"'+device_id+'", \
"method":"Switch.Set", \
"port":"'+str(port)+'", \
"src": "restapi/solution/iot/dk9mbs/status/rpc", \
"status":"'+value+'"}'
        location=IotLocation(context, device_id)
        client.publish(f"restapi/solution/iot/dk9mbs/switch/{device.id.value}/rpc", payload)

    params['output']['status_code']=200
    params['output']['payload']="OK"



def __get_config_value(config, name, default):
    if name in config:
        return config[name]

    return default
