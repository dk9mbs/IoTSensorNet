import datetime
import requests
import json
import paho.mqtt.client as mqtt

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
from core.setting import Setting
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

    now=datetime.datetime.now()
    config=plugin_context['config']

    device=params['input']['device']
    command=params['input']['command']
    value=params['input']['value']
    session_id=params['input']['session_id']

    device_model=iot_device.objects(context).select().where(iot_device.id==device).to_entity()
    if device_model == None:
        logger.error(f"Device not found: {device}")
        raise Exception(f"Device not found: {device}")

    username=Setting.get_value(context, "mqtt.username","username")
    password=Setting.get_value(context, "mqtt.password","password")
    host=Setting.get_value(context, "mqtt.host","mqtt.host.de")
    port=int(Setting.get_value(context, "mqtt.port",1883))

    client=mqtt.Client()
    client.username_pw_set(username=username, password=password)
    client.connect(host, port)
    client.publish("test/hallo", "on")
    client.disconnect()

    params['output']['status_code']=200
    params['output']['payload']="OK"



def __get_config_value(config, name, default):
    if name in config:
        return config[name]

    return default
