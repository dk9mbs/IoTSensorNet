import datetime
import json

#from core.fetchxmlparser import FetchXmlParser
#from services.database import DatabaseServices
from core import log
from shared.model import *
#from services.mqtt_client import MqttClient

logger=log.create_logger(__name__)

def __validate(params):
    if 'params' not in params:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return

    icon="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSINM0jv55Gjz5RyFDJgJJlDtCx7ocTVAfP5AWKWI_cMbbC7PCU0RjTwyMZqwaobM4VZkQ&usqp=CAU"

    #params['params']['iot_items']=[
    #    {"_type":"device","description":"Strahler Garten vorne","internal_device_id":"SHELLY_TEST", "icon": icon}, 
    #    {"_type":"device","description":"Steckdose Flur (Spiegel)","internal_device_id":"flur.spiegel.steckdose1", "icon":icon}, 
    #    {"_type":"device","description":"Wohnzimmer Lampe","internal_device_id":"wohnzimmer.fenster.lampe1", "icon":icon}, 
    #    {"_type":"device","description":"Schlafzimmer Steckdose","internal_device_id":"schlafzimmer.fenster.steckdose", "icon":icon}, 
    #    {"_type":"device","description":"Labor Lampe<br>","internal_device_id":"labor.fenster.lampe1", "icon":icon}, 
    #    {"_type":"device","description":"Küche Lampe<br>","internal_device_id":"kueche.fenster.lampe1", "icon":icon}, 
    #    {"_type":"device","description":"Sofa Lampe1<br>","internal_device_id":"wohnzimmer.sofa.lampe1", "icon":icon}, 
    #    {"_type":"device","description":"Sofa Lampe 2<br>","internal_device_id":"wohnzimmer.sofa.lampe2", "icon":icon}, 
    #    {"_type":"device","description":"Wohnzimmer Vitrine Essecke","internal_device_id":"wohnzimmer.essecke.vitrine", "icon":icon}, 
    #]

    items=[]
    routing_list=iot_device_routing.objects(context).select().where(iot_device_routing.show_dashboard==-1).to_list()
    for routing in routing_list:
        item={"_type":"device", "description":routing.description.value,"internal_device_id":routing.internal_device_id.value, "icon":icon}
        #print(item)
        items.append(item)    
   
    params['params']['iot_items']=items
    
    
    

