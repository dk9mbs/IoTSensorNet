import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log

logger=log.create_logger(__name__)

def __validate(params):
    if 'data' not in params:
        return False
    if 'value' not in params['data']:
        return False
    if 'id' not in params['data']:
        return False
    if 'external_sensor_id' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params {params}")
        return

    print(params)
    value=params['data']['value']['value']
    external_sensor_id=params['data']['external_sensor_id']['value']
    id=params['data']['id']['value']
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="insert">
        <table name="iot_sensor_data"/>
        <fields>
            <field name="sensor_id" value="{external_sensor_id}"/>
            <field name="sensor_namespace" value="manual"/>
            <field name="sensor_value" value="{value}"/>
        </fields>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)


    fetch=f"""
    <restapi type="update">
        <table name="iot_manual_sensor_data"/>
        <fields>
            <field name="status_id" value="20"/>
        </fields>
        <filter>
            <condition field="id" value="{id}"/>
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)
