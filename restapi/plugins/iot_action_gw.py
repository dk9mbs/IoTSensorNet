import datetime
import requests
import json

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log, jsontools

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
    url=__get_location_url(context, params['input']['device'])
    #url=__get_config_value(config, "endpoint", "http://localhost:5001/$sessionid$/$device$/$command$/$value$")
    timeout=int(__get_config_value(config, "timeout", "15"))

    url=url.replace("$session_id$", params['input']['session_id'])
    url=url.replace("$device$", params['input']['device'])
    url=url.replace("$command$", params['input']['command'])
    url=url.replace("$value$", params['input']['value'])

    r = requests.get(url, json={}, timeout=timeout)

    params['output']['status_code']=r.status_code
    params['output']['payload']=r.text

def __get_config_value(config, name, default):
    if name in config:
        return config[name]

    return default

def __get_location_url(context, device_id):
    fetch_xml=f"""<restapi type="select">
    <table name="iot_device" alias="d"/>
    <filter type="or">
        <condition field="internal_device_id" alias="r" value="{device_id}" operator="="/>
    </filter>
    <joins>
        <join type="inner" table="iot_device_routing" alias="r" condition="r.external_device_id=d.id"/>
        <join type="inner" table="iot_location" alias="l" condition="d.location_id=l.id"/>
    </joins>
    <orderby>
        <field name="created_on" alias="d" sort="DESC"/>
    </orderby>
    <select>
        <field name="id" table_alias="d"/>
        <field name="location_id" table_alias="d"/>
        <field name="local_gateway_url" table_alias="l"/>
    </select>
    </restapi>"""
    fetchparser=FetchXmlParser(fetch_xml, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=False)

    if rs.get_eof():
        raise Exception(f"Location for {device_id} not found!")

    loc=rs.get_result()

    if loc['local_gateway_url'] == '' or loc['local_gateway_url'] == None:
        raise Exception(f"Location url for {device_id} is empty!")

    return loc['local_gateway_url']
