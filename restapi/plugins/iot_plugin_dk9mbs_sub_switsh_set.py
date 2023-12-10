import datetime
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log
from shared.model import *
from services.mqtt_client import MqttClient

logger=log.create_logger(__name__)

def __validate(params):
    if 'data' not in params:
        return False
    if 'method' not in params['data']:
        return False
    if 'id' not in params['data']:
        return False
    if 'topic' not in params:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return


    #iot_restapi/dk9mbs/status/rpc {"id":"ebbeflut","method":"Notify","port":"0",
    # "src":"1234567890","status":"off","dst":"iot_restapi/dk9mbs/status"}

    method=params['data']['method']
    internal_id=params['data']['id']
    topic=params['topic']
    external_id=params['data']['src']
    status=params['data']['status']
    port=params['data']['port']
    internal_value=status

    if method!="Notify":
        logger.info(f"Method is not for me: {method}")
        return

    with MqttClient(context) as client:
        payload=json.dumps({"internal_device_id":internal_id,
            "external_device_id":external_id, 
            "value":status, "channel": port})

        topic=f"restapi/extension/iot/device/{internal_id}"
        client.publish(topic, payload, retain=True)

    device=iot_device.objects(context).select().where(iot_device.id==external_id)
    if device==None:
        logger.warning(f"Device not found in iot_device {external_id}")
        return

    device_attr=iot_device_attribute.objects(context).select().where(iot_device_attribute.name=="power") \
        .where(iot_device_attribute.vendor_id=="dk9mbs").where(iot_device_attribute.class_id=="dk9mbs_io_node").to_entity()
    if device_attr==None:
        raise Exception(f"iot_device_attribute not found: name:power vendor_id:shelly class_id:shellyplus1")

    device_attr_val=iot_device_attribute_value.objects(context).select().where(iot_device_attribute_value.device_id==external_id) \
        .where(iot_device_attribute_value.device_attribute_id==device_attr.id.value).to_entity()
    
    if device_attr_val==None:
        device_attr_val=iot_device_attribute_value()
        device_attr_val.device_id.value=external_id
        device_attr_val.device_attribute_id.value=device_attr.id.value
        device_attr_val.value.value=internal_value
        device_attr_val.insert(context)
    else:
        device_attr_val.value.value=internal_value
        device_attr_val.update(context)
