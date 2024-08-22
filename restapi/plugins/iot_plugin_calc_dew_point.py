import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from core import log

from iot_common import get_sensor_value
from iot_lib_dew_point import iot_LibDewPoint

logger=log.create_logger(__name__)

def __validate(params):
    if 'data' not in params:
        return False
    if 'sensor_value' not in params['data']:
        return False
    if 'sensor_id' not in params['data']:
        return False

    return True

def execute(context, plugin_context, params):
    if not __validate(params):
        logger.warning(f"Missings params")
        return

    value=params['data']['sensor_value']['value']
    sensor_id=params['data']['sensor_id']['value']
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="select">
        <table name="iot_dew_point_sensor"/>
        <filter type="or">
            <condition field="temp_sensor_id" value="{sensor_id}"/>
            <condition field="rel_hum_sensor_id" value="{sensor_id}"/>
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=0, run_as_system=True)

    if not rs.get_eof():
        for rec in rs.get_result():
            temp_c=float(get_sensor_value(context, rec['temp_sensor_id'],"last_value", 0))
            rel_hum=float(get_sensor_value(context, rec['rel_hum_sensor_id'],"last_value", 0))
            dew_point=iot_LibDewPoint(temp_c, rel_hum)
            dew_point.calc()

            if not rec['dew_point_sensor_id'] == None:
                fetch=f"""
                <restapi type="insert">
                    <table name="iot_sensor_data"/>
                    <fields>
                        <field name="sensor_id" value="{rec['dew_point_sensor_id']}"/>
                        <field name="sensor_namespace" value="restapi"/>
                        <field name="sensor_value" value="{dew_point.get_dew_point()}"/>
                    </fields>
                </restapi>
                """

                fetchparser=FetchXmlParser(fetch, context)
                DatabaseServices.exec(fetchparser, context, run_as_system=True)            

            if not rec['aps_hum_sensor_id'] == None:
                fetch=f"""
                <restapi type="insert">
                    <table name="iot_sensor_data"/>
                    <fields>
                        <field name="sensor_id" value="{rec['abs_hum_sensor_id']}"/>
                        <field name="sensor_namespace" value="restapi"/>
                        <field name="sensor_value" value="0"/>
                    </fields>
                </restapi>
                """

                #fetchparser=FetchXmlParser(fetch, context)
                #DatabaseServices.exec(fetchparser, context, run_as_system=True)            