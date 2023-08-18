import datetime
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log
from shared.model import *
from services.mqtt_client import MqttClient

logger=log.create_logger(__name__)

def __validate(params):
    if 'params' not in params:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return
    print("**********************************************************************")
    icon="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSINM0jv55Gjz5RyFDJgJJlDtCx7ocTVAfP5AWKWI_cMbbC7PCU0RjTwyMZqwaobM4VZkQ&usqp=CAU"

    params['params']['iot_items']=[
        {"_type":"device","description":"Strahler Garten vorne","internal_device_id":"SHELLY_TEST", "icon": icon}, 
        {"_type":"device","description":"Steckdose Flur (Spiegel)","internal_device_id":"flur.spiegel.steckdose1", "icon":icon}, 
        {"_type":"device","description":"Lampe Wohnzimmer","internal_device_id":"wohnzimmer.fenster.lampe1", "icon":icon}, 
    ]


