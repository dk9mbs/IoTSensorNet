import datetime
import requests
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
from core.setting import Setting
from shared.model import *
from services.mqtt_client import MqttClient

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

    now=datetime.datetime.now()
    config=plugin_context['config']

    device_id=params['input']['device']
    command=params['input']['command']
    value=params['input']['value']
    session_id=params['input']['session_id']

    if value=='on':
        value="true"
    else:
        value="false"

    #mosquitto_pub -h dk9mbs.de -u user -P password -p 1883 -t shellyplus1-441793ccf49c/rpc -m 
    # '{"id":0, "src":"trockner/status", "method":"Switch.Set", "params":{"id":0,"on":true}}'
    #
    #mosquitto_pub -h dk9mbs.de -u user -P password -p 1883 -t shellyplus1-441793ccf49c/rpc -m 
    # '{"id":123, "src":"mynewtopic", "method":"Shelly.GetStatus"}'

    routing=iot_device_routing.objects(context).select().where(iot_device_routing.internal_device_id==device_id).to_entity()
    if routing==None:
        logger.error(f"Devicerouting not found: {device_id}")
        raise Exception(f"Devicerouting not found: {device_id}")

    device=iot_device.objects(context).select().where(iot_device.id==routing.external_device_id.value).to_entity()
    if device == None:
        logger.error(f"Device not found: {device_id}")
        raise Exception(f"Device not found: {device_id}")


    with MqttClient(context) as client:
        payload='{"id":0, "src":"dk9mbs/shelly/status", "method":"Switch.Set", "params":{"id":0,"on":'+value+'}}'
        topic=f"{device.id.value}/rpc"
        client.publish(topic, payload)

    params['output']['status_code']=200
    params['output']['payload']="OK"



def __get_config_value(config, name, default):
    if name in config:
        return config[name]

    return default
