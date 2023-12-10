import datetime
import requests
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools
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

    use_http=False
    use_mqtt=True
    port=0

    now=datetime.datetime.now()
    config=plugin_context['config']
    #protocol,url,topic=_get_location_url(context, params['input']['device'])
    location=IotLocation(context, params['input']['device'])
    protocol=location.get_location_gateway_protocol()
    url=location.get_location_gateway_url()
    topic=location.get_location_gateway_topic()

    if 'port' in params['input']:
        port=params['input']['port']

    if protocol=="http":
        timeout=int(_get_config_value(config, "timeout", "15"))

        url=url.replace("$session_id$", params['input']['session_id'])
        url=url.replace("$device$", params['input']['device'])
        url=url.replace("$command$", params['input']['command'])
        url=url.replace("$value$", params['input']['value'])
        url=url.replace("$port$", params['input']['port'])
        r = requests.get(url, json={}, timeout=timeout)

        params['output']['status_code']=r.status_code
        params['output']['payload']=r.text
    elif protocol=="mqtt":
        from services.mqtt_client import MqttClient
        session_id=params['input']['session_id']
        internal_device_id=params['input']['device']
        attribute=params['input']['command']
        value=params['input']['value']

        with MqttClient(context) as client:
            payload={"session_id":session_id, "internal_device_id":internal_device_id,
                "attribute":attribute,"value":value, "port": port}
            client.publish(topic, json.dumps(payload))

        params['output']['status_code']=200
        params['output']['payload']=""


def _get_config_value(config, name, default):
    if name in config:
        return config[name]

    return default
