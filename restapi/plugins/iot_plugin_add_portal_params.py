import datetime
import json

from core import log
from shared.model import *

logger=log.create_logger(__name__)

def __validate(params):
    if 'params' not in params:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return

    items=[]
    routing_list=iot_device_routing.objects(context).select().where(iot_device_routing.show_dashboard==-1).to_list()
    for routing in routing_list:
        device=iot_device.objects(context).select().where(iot_device.id==routing.external_device_id.value).to_entity()

        if device!=None:
            icon=device.icon.value
        else:
            icon=""

        item={"_type":"device", "description":routing.description.value,
            "internal_device_id":routing.internal_device_id.value, "icon":icon}
        items.append(item)    
   
    params['params']['iot_items']=items
    
    
    

