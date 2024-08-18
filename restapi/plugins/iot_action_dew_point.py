import datetime
import requests
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
from core.setting import Setting
from shared.model import *
from services.mqtt_client import MqttClient
from iot_lib_dew_point import iot_LibDewPoint

logger=log.create_logger(__name__)

def __validate(params):
    if 'input' not in params:
        return False
    if 'temperature' not in params['input']:
        return False
    if 'humidity' not in params['input']:
        return False

    return True

def config():
    return {"raise_exception": True}

def execute(context, plugin_context, params):
    params['output']['success']=False
    
    if not __validate(params):
        logger.error(f"Missings params")
        return

    temperatur=float(params['input']['temperature'])
    humidity=float(params['input']['humidity'])

    dew_point=iot_LibDewPoint(temperatur, humidity)
    dew_point.calc()

    params['output']['success']=True
    params['output']['dew_point']=dew_point.get_dew_point()
    params['output']['temperatur']=temperatur
    params['output']['humidity']=humidity


