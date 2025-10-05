import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log

logger=log.create_logger(__name__)

def _validate(params):
    if 'data' not in params:
        return False
    if 'sensor_value' not in params['data']:
        return False
    if 'sensor_id' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params")
        return

    value=params['data']['sensor_value']['value']
    sensor_id=params['data']['sensor_id']['value']
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="update">
        <table name="iot_sensor"/>
        <fields>
            <field name="last_value" value="{value}"/>
            <field name="last_value_on" value="{now}"/>
        </fields>
        <filter>
            <condition field="id" value="{sensor_id}"/>
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)
