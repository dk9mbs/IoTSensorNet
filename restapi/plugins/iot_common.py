from flask import g
import datetime

from core.fetchxmlparser import FetchXmlParser
from core import log
from services.database import DatabaseServices
from services.fetchxml import build_fetchxml_by_alias
from services.numerictools import isnumeric

logger=log.create_logger(__name__)

def set_node_last_heard(context, node_name, node_version="---"):
    now=datetime.datetime.now()
    fetch=f"""
    <restapi type="update">
        <table name="iot_node"/>
        <fields>
            <field name="last_heard_on" value="{now}"/>
            <field name="version" value="{node_version}"/>
        </fields>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    DatabaseServices.exec(fetchparser, context, run_as_system=True)


def get_node_by_node_name(context, node_name):
    fetch=f"""
    <restapi type="select">
        <table name="iot_node" alias="n"/>
        <select>
            <field name="id" table_alias="n"/>
            <field name="display_template" table_alias="n"/>
        </select>
        <filter>
            <condition field="name" value="{node_name}" operator="="/>
        </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)
    return rs


def get_numeric_sensor_value(context, sensor_id, field_name, format="", default_value=0):
    value= __get_sensor_by_sensor_id(context,sensor_id,field_name, format=format, default_value=default_value)

    if value==__error_not_found():
        logger.error(f"Error not found:{value}")
        return default_value

    if format!="" and isnumeric(value):
        return format.format(float(value))
    else:
        logger.error(f"Value is not numeric! :{value}")
        return default_value


def get_sensor_value(context, sensor_id, field_name, default_value=""):
    return __get_sensor_by_sensor_id(context,sensor_id,field_name, default_value=default_value)


def __get_sensor_by_sensor_id(context, sensor_id, field_name, format="", default_value=""):
    fetch=f"""
    <restapi type="select">
    <table name="iot_sensor" alias="s"/>
    <select>
        <field name="{field_name}" table_alias="s" alias="value"/>
    </select>
    <filter>
        <condition field="id" value="{sensor_id}" operator="="/>
    </filter>
    </restapi>
    """
    fetchparser=FetchXmlParser(fetch, context)
    rs=DatabaseServices.exec(fetchparser, context, fetch_mode=1, run_as_system=True)

    if rs.get_eof():
        rs.close()
        logger.error(f"Error not found:{fetch}")
        return __error_not_found

    value=rs.get_result()['value']
    rs.close()

    if format!="" and isnumeric(value):
        return format.format(float(value))
    else:
        return value

def __error_not_found():
    return "!na"

