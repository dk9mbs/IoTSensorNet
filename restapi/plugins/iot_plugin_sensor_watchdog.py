import datetime

from core.fetchxmlparser import FetchXmlParser
from core import log
from services.database import DatabaseServices
from services.activity import Activity

logger=log.create_logger(__name__)

def _validate(params):
    if 'data' not in params:
        return False
    return True

def execute(context, plugin_context, params):
    if not _validate(params):
        logger.warning(f"Missings params")
        return

    fetch=f"""
    <restapi type="select">
        <table name="iot_sensor" alias="a"/>
        <select>
            <field name="id" table_alias="a"/>
            <field name="description" table_alias="a"/>
            <field name="last_value" table_alias="a"/>
            <field name="last_value_on" table_alias="a"/>
            <field name="unit" table_alias="a"/>
        </select>

        <filter type="and">
            <condition field="last_value" value="0" operator="notnull" />
            <condition field="last_value_on" value="10" operator="olderThenXMinutes" />
            <condition field="notify" value="0" operator="neq" />
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, run_as_system=True)
    if not rs.get_eoif():
        tools=Activity(context)
        tools.create_alert_if_not_exists("IOT Sensor Fehler (Watchdog)", "Ein oder mehrere Sensoren liefern keine Messwerte!", "iot-sensoer-watchdog-error", 1)
    