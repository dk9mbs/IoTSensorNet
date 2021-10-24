import datetime

from core.fetchxmlparser import FetchXmlParser
from services.database import DatabaseServices
from services.fetchxml import build_fetchxml_by_alias
from core import log


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
    external_sensor_id=params['data']['sensor_id']['value']

    # check if exists a internal_sensor_id with the external id
    if __sensor_exists(context, external_sensor_id):
        internal_sensor_id=external_sensor_id
    else:
        internal_sensor_id=None

    rs=__read_routing_by_external(context,external_sensor_id)

    if rs.get_eof():

        __create_routing(context, internal_sensor_id, external_sensor_id)

    else:
        if rs.get_result()['status_id']==20:
            raise Exception(f"External Sensor {external_sensor_id} is disabled!!!")

        internal_sensor_id=rs.get_result()['internal_sensor_id']

        __set_last_value_on(context, external_sensor_id)


    logger.info(f"external_sensor_id: {external_sensor_id} internal_sensor_id: {internal_sensor_id}")

    if internal_sensor_id==None or internal_sensor_id=="":
        raise Exception(f"Sensor not registered: {external_sensor_id}")

    params['data']['sensor_id']['value']=internal_sensor_id



def __sensor_exists(context, sensor_id):
    fetch=build_fetchxml_by_alias(context,"iot_sensor",id=sensor_id,type="select")
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)
    if rs.get_eof():
        return False
    else:
        return True

def __read_routing_by_external(context, external_sensor_id):
    fetch=f"""
    <restapi type="select">
        <table name="iot_sensor_routing" alias="sr"/>
        <select>
            <field name="internal_sensor_id" table_alias="sr" />
            <field name="status_id" table_alias="sr" />
        </select>
        <filter type="and">
            <condition field="external_sensor_id" value="{external_sensor_id}" operator="=" />
        </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)

    return rs

def __create_routing(context,internal_sensor_id, external_sensor_id):
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="insert">
        <table name="iot_sensor_routing" alias="sr"/>
        <fields>
            <field name="internal_sensor_id" value="{internal_sensor_id}" />
            <field name="external_sensor_id" value="{external_sensor_id}" />
            <field name="description" value="auto generated" />
            <field name="last_value_on" value="{now}" />
            <field name="status_id" value="0" />
        </fields>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, run_as_system=True)

def __set_last_value_on(context,external_sensor_id):
    now=datetime.datetime.now()

    fetch=f"""
    <restapi type="update">
        <table name="iot_sensor_routing" alias="sr"/>
        <fields>
            <field name="last_value_on" value="{now}" />
        </fields>
        <filter type="and">
            <condition field="external_sensor_id" value="{external_sensor_id}" operator="=" />
         </filter>
    </restapi>
    """

    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, run_as_system=True)

