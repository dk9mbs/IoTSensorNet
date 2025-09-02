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
    if 'addr' not in params['data']:
        return False
    if 'service_data' not in params['data']:
        return False
    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params {params}")
        return

    addr=params['data']['addr']
    humidity=None
    temperature=None

    if 'humidity' in params['data']['service_data']:
        humidity=params['data']['service_data']['humidity']
        logger.info(f"Rel. Luftfeuchtigkeit in %: {humidity} {addr}")

    if 'temperature' in params['data']['service_data']:
        temperature=params['data']['service_data']['temperature']
        logger.info(f"Temperatur in c°: {temperature} {addr}")

    if humidity!=None:
        sensor_data=iot_sensor_data()
        sensor_data.sensor_id.value=f"{addr}.hum"
        sensor_data.sensor_namespace.value='shelly.ble'
        sensor_data.sensor_value.value=humidity
        sensor_data.insert(context)

    if temperature!=None:
        sensor_data=iot_sensor_data()
        sensor_data.sensor_id.value=f"{addr}.temp"
        sensor_data.sensor_namespace.value='shelly.ble'
        sensor_data.sensor_value.value=temperature
        sensor_data.insert(context)


