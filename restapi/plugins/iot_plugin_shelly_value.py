import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log
from shared.model import *

logger=log.create_logger(__name__)

def __validate(params):
    if 'data' not in params:
        return False
    if 'method' not in params['data']:
        return False
    if 'id' not in params['data']:
        return False
    if 'params' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return


    shelly_method=params['data']['method']
    shelly_params=params['data']['params']
    shelly_id=params['data']['id']

    if shelly_method!="Switch.Set":
        logger.info(f"Method is not for me: {shelly_method}")

    device_attr=iot_device_attribute.objects(context).select().where(iot_device_attribute.name=="power") \
        .where(iot_device_attribute.vendor_id=="shelly").where(iot_device_attribute.class_id=="shellyplus1").to_entity()
    
    if device_attr==None:
        raise Exception(f"iot_device_attribute not found: name:power vendor_id:shelly class_id:shellyplus1")

    device_attr_val=iot_device_attribute_value.objects(context).select().where(iot_device_attribute_value.device_id=="test").to_entity()
    if device_attr_val==None:
        device_attr_val=iot_device_attribute_value()
        device_attr_val.device_id.value=""
        device_attr_val.device_attribute_id.value=device_attr.id.value
        device_attr_val.value.value=shelly_params['on']
        device_attr_val.insert(context)

